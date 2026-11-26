"""Codex adapter for Obsidian's project-local tool discipline."""

import fcntl
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
GRAPH = ROOT / "graphify-out" / "graph.json"
AUDIT = ROOT / ".agent-output-audit.jsonl"
AUDIT_LIMIT = 64 * 1024
EXPLORATION = {"rg", "grep", "cat", "head", "tail", "ls", "tree", "find", "nl"}
READ_ONLY_GIT = {"status", "diff", "log", "show", "ls-files", "grep"}
NOISY_SCRIPTS = {"run-package-suite.sh", "run-ecosystem-suite.sh", "run-benchmarks.sh", "run-file-stress.sh"}
SEPARATORS = {";", "|", "||", "&&", "&", "(", ")"}


def emit(event, **fields):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, **fields}}))


def deny(reason):
    emit("PreToolUse", permissionDecision="deny", permissionDecisionReason=reason)


def command_segments(command):
    # Inspect text only. This is a tool-usage rule, not a shell sandbox.
    for line in command.splitlines():
        try:
            lex = shlex.shlex(line, posix=True, punctuation_chars=";&|()")
            lex.whitespace_split = True
            tokens = list(lex)
        except ValueError:
            continue
        segment = []
        for token in tokens:
            if token in SEPARATORS:
                if segment:
                    yield segment
                segment = []
            else:
                segment.append(token)
        if segment:
            yield segment


def needs_rtk(command):
    for args in command_segments(command):
        while args and ("=" in args[0] or args[0] in {"env", "command"}):
            args = args[1:]
        if not args:
            continue
        tool = Path(args[0]).name
        if tool in EXPLORATION or (tool == "sed" and args[1:2] == ["-n"]):
            return True
        if tool == "git" and len(args) > 1 and args[1] in READ_ONLY_GIT:
            return True
        if tool == "gh" and len(args) >= 3 and args[2] in {"list", "view", "status"}:
            return True
        if tool == "noxc" and len(args) > 1 and args[1] in {"build", "test"}:
            return True
        if tool in {"bash", "sh"} and len(args) > 1 and Path(args[1]).name in NOISY_SCRIPTS:
            return True
    return False


def graphify(kind, payload):
    program = shutil.which("graphify")
    if not program or not GRAPH.is_file() or GRAPH.resolve() != GRAPH:
        return ""
    args = [program, "hook-guard", kind]
    if kind != "compact":
        args.append("--strict")
    try:
        event = {key: payload[key] for key in ("hook_event_name", "source", "session_id", "tool_name", "tool_input", "cwd") if key in payload}
        result = subprocess.run(
            args, cwd=ROOT, input=json.dumps(event), capture_output=True, text=True,
            timeout=3, env={**os.environ, "CLAUDE_PROJECT_DIR": str(ROOT), "GRAPHIFY_OUT": str(GRAPH.parent)},
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired, UnicodeError):
        return ""
    return result.stdout if result.returncode == 0 else ""


def pre(payload):
    tool = payload.get("tool_name") or ""
    args = payload.get("tool_input") or {}
    if tool == "Bash":
        command = args.get("command", "")
        if isinstance(command, str) and needs_rtk(command):
            deny("Use RTK for exploration and test output. Try rtk rg, rtk read, rtk git, rtk gh or rtk run. Use rtk bypass for exact output.")
            return
        if not isinstance(command, str):
            return
        # Limit Graphify payloads to explicitly wrapped discovery commands.
        segments = list(command_segments(command))
        if len(segments) != 1:
            return
        words = segments[0]
        if len(words) < 3 or Path(words[0]).name != "rtk" or words[1] not in {"rg", "grep", "read"}:
            return
        if words[1] == "read":
            payload = {**payload, "tool_name": "Read", "tool_input": {"file_path": words[2]}}
        else:
            payload = {**payload, "tool_input": {"command": shlex.join(words[1:])}}
        kind = "search"
    elif tool in {"Grep", "mcp__filesystem__search_files"}:
        payload = {**payload, "tool_name": "Grep", "tool_input": {
            "pattern": args.get("pattern", ""), "path": args.get("path", "."),
        }}
        kind = "search"
    else:
        if tool.startswith("mcp__filesystem__"):
            payload = {**payload, "tool_name": "Read", "tool_input": {"file_path": args.get("path", "")}}
        kind = "read"
    if payload.get("tool_name") == "Read":
        kind = "read"
        path_value = (payload.get("tool_input") or {}).get("file_path")
        if isinstance(path_value, str) and path_value.endswith(".nox") and GRAPH.is_file():
            target = (Path(payload.get("cwd") or ROOT) / path_value).resolve()
            if ROOT not in target.parents or not target.is_file() or target.stat().st_mtime_ns > GRAPH.stat().st_mtime_ns:
                return
            # Graphify's Read extension list lacks NOX. Its strict targeted Grep
            # path checks the indexed file and shares the same intervention budget.
            payload = {**payload, "tool_name": "Grep", "tool_input": {"path": str(target), "pattern": target.stem}}
            kind = "search"
    result = graphify(kind, payload)
    if not result:
        return
    try:
        outcome = json.loads(result)
    except ValueError:
        outcome = {}
    if not isinstance(outcome, dict):
        outcome = {}
    fields = outcome.get("hookSpecificOutput") or {}
    if fields.get("permissionDecision") == "deny" or outcome.get("decision") == "block":
        deny("Query the fresh project graph with graphify query or graphify explain, then read the exact source.")
    else:
        emit("PreToolUse", additionalContext="Graphify has indexed this project. Prefer a targeted query, then verify exact source when needed.")


def audit(payload):
    tool = payload.get("tool_name", "")
    label = "shell" if tool == "Bash" else "discovery"
    size = len(json.dumps(payload.get("tool_response"), ensure_ascii=False).encode())
    row = json.dumps({"tool": label, "response_bytes": size}) + "\n"
    try:
        fd = os.open(AUDIT, os.O_CREAT | os.O_RDWR | os.O_APPEND | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, "a", encoding="utf-8") as output:
            fcntl.flock(output, fcntl.LOCK_EX)
            if os.fstat(output.fileno()).st_size >= AUDIT_LIMIT:
                output.truncate(0)
            output.write(row)
    except OSError:
        pass
    if size >= 20_000:
        emit("PostToolUse", additionalContext="This result is large. Use a narrower RTK read or search when exact full output is unnecessary.")


def main():
    payload = json.load(sys.stdin)
    event = payload["hook_event_name"]
    mode = sys.argv[1]
    if mode == "pre":
        pre(payload)
    elif mode == "audit":
        audit(payload)
    elif mode == "compact":
        if graphify("compact", {**payload, "source": "compact"}):
            emit(event, additionalContext="After compaction, resume with graphify query or explain and use RTK for focused terminal output.")
    elif mode == "session":
        missing = [tool for tool in ("rtk", "graphify") if not shutil.which(tool)]
        message = "Obsidian tool discipline applies to all project agents. Use RTK for discovery and graphify for indexed source. Use rtk bypass for exact output or diagnostics."
        if missing:
            message += " Missing tools: " + ", ".join(missing) + "."
        if not GRAPH.is_file() and "graphify" not in missing:
            try:
                subprocess.run([sys.executable, str(ROOT / "scripts/hooks/build_graph.py")],
                               cwd=ROOT, capture_output=True, timeout=3, check=False)
            except (OSError, subprocess.TimeoutExpired):
                pass
        if not GRAPH.is_file():
            message += " Build the local NOX graph with python3 scripts/hooks/build_graph.py."
        emit(event, additionalContext=message)


if __name__ == "__main__":
    main()
