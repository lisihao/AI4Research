#!/usr/bin/env python3
"""Contract tests for the thin Code-as-Harness delivery adapter."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


class AgentGovernanceAdapterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.profile = json.loads(
            (ROOT / ".agent-governance/profile.json").read_text(encoding="utf-8")
        )

    def test_profile_delegates_to_repository_native_gates(self) -> None:
        commands = {
            gate["id"]: gate["command"] for gate in self.profile["gates"]
        }
        self.assertEqual(
            commands["native-fast"], ["bash", "scripts/test-local-fast.sh"]
        )
        self.assertEqual(
            commands["native-full"], ["bash", "scripts/test-local-full.sh"]
        )
        self.assertNotIn(
            ["python3", "scripts/check-secret-scan.py"], commands.values()
        )

    def test_adapter_does_not_create_a_second_runtime_state_tree(self) -> None:
        governance_files = sorted(
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / ".agent-governance").rglob("*")
            if path.is_file()
        )
        self.assertEqual(governance_files, [".agent-governance/profile.json"])
        self.assertFalse((ROOT / ".agent-governance/task_graph.json").exists())
        self.assertFalse((ROOT / ".agent-governance/evidence").exists())

    def test_pre_push_requires_fresh_full_attestation(self) -> None:
        hook = (ROOT / ".githooks/pre-push").read_text(encoding="utf-8")
        self.assertIn("--scope auto", hook)
        self.assertIn("--level full", hook)
        self.assertIn("--report @git", hook)
        self.assertIn("--require-level full", hook)

    def test_ci_publishes_attestation_without_replacing_solar_ci(self) -> None:
        workflow = (ROOT / ".github/workflows/agent-governance.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("--scope ci-contract", workflow)
        self.assertIn("actions/upload-artifact@v4", workflow)
        self.assertTrue((ROOT / ".github/workflows/solar-ci.yml").is_file())

    def test_required_ci_does_not_hide_pull_request_failures(self) -> None:
        for relative_path in (
            ".github/workflows/solar-ci.yml",
            ".github/workflows/install-matrix.yml",
        ):
            workflow = (ROOT / relative_path).read_text(encoding="utf-8")
            self.assertNotIn(
                "continue-on-error:",
                workflow,
                f"{relative_path} must fail closed on pull requests and pushes",
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
