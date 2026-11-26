# Project agent tools

Obsidian declares its Codex hooks in `.codex/hooks.json`. They apply to supported tool paths in trusted local Codex sessions for this checkout. The project instructions also cover agents on surfaces that do not run these hooks.

Install RTK, Graphify and Python 3 on the local PATH. Review the project hooks via `/hooks` in Codex CLI or **Settings → Hooks** in the desktop app. Codex requires per-definition trust for project hooks. The existing user-level `rtk hook codex` can continue rewriting compatible commands. This project does not register a second rewriter.

| NOX Claude workflow | Obsidian Codex hook |
|---|---|
| Session and subagent rules | `SessionStart` and `SubagentStart` inject the project tool conventions |
| Graphify compaction reset | `SessionStart` with matcher `compact` calls the Graphify reset |
| Strict search and read hooks | `PreToolUse` rejects recognized raw shell discovery and noisy test commands, and delegates indexed reads/searches to Graphify |
| Output audit | `PostToolUse` records tool category and response byte count in a bounded, ignored local file |

The shell guard checks recognized command positions. It leaves the host permission prompt, sandbox and tool approval rules in place. Use `rtk bypass` for format comparisons, exact output and diagnosis. Graphify can redirect the first eligible indexed read/search to a query. It allows exact reads afterward under its normal session-budget rules. Stale or missing graph data should be refreshed before relying on a query. The generated graph includes tracked NOX declarations and local imports, with file/line references. It contains no file bodies or credentials and stays out of Git.

```sh
python3 scripts/hooks/build_graph.py
graphify explain Logger
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/hooks
```

The session hook builds a missing index locally when Graphify is available. Refresh it after editing NOX, especially before a fresh source investigation or commit. The audit file `.agent-output-audit.jsonl` is local, capped at approximately 64 KiB, and contains no commands, arguments, raw results, file paths or session identifiers.

Sources: [Codex hook registration and trust](https://learn.chatgpt.com/docs/hooks) and [NOX's corresponding Claude hook configuration](https://github.com/mburakmmm/nox-lang/blob/22a4d80b76f2450ac71cbff4f1831b0b1b84b0b4/.claude/settings.json).
