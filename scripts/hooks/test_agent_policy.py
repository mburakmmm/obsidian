import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import agent_policy as policy


def observe(handler, payload):
    capture = io.StringIO()
    with contextlib.redirect_stdout(capture):
        handler(payload)
    result = capture.getvalue()
    return json.loads(result).get("hookSpecificOutput", {}) if result else {}


class AgentPolicyTests(unittest.TestCase):
    def test_raw_discovery_or_test_command_requires_rtk(self):
        for command in ("rg Logger", "git status", "rtk git status && cat logger.nox",
                        "env MODE=ci noxc test", "bash scripts/run-package-suite.sh llvm"):
            with self.subTest(command=command):
                output = observe(policy.pre, {"tool_name": "Bash", "tool_input": {"command": command}})
                self.assertEqual(output["permissionDecision"], "deny")

    def test_wrapped_commands_and_writes_keep_host_approval(self):
        with patch.object(policy, "graphify", return_value=""):
            for command in ("rtk rg Logger", "rtk bypass cat logger.nox",
                            "rtk run bash scripts/run-package-suite.sh llvm",
                            "git commit -m 'mention cat and rg'", "git push origin main"):
                with self.subTest(command=command):
                    self.assertEqual(observe(policy.pre, {"tool_name": "Bash", "tool_input": {"command": command}}), {})

    def test_graphify_deny_becomes_static_codex_deny(self):
        result = json.dumps({"hookSpecificOutput": {"permissionDecision": "deny", "permissionDecisionReason": "synthetic-private-text"}})
        with patch.object(policy, "graphify", return_value=result) as guard:
            output = observe(policy.pre, {"tool_name": "mcp__filesystem__search_files", "tool_input": {"pattern": "Logger"}})
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertNotIn("synthetic-private-text", str(output))
        self.assertEqual(guard.call_args.args[1]["tool_name"], "Grep")

    def test_audit_persists_only_bounded_metadata(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "audit.jsonl"
            output.write_text(" " * policy.AUDIT_LIMIT)
            with patch.object(policy, "AUDIT", output):
                observe(policy.audit, {"tool_name": "Bash", "tool_input": {"command": "private"},
                                       "tool_response": "synthetic-private-text"})
            self.assertEqual(json.loads(output.read_text()), {"tool": "shell", "response_bytes": 24})


if __name__ == "__main__":
    unittest.main()
