#!/usr/bin/env bash
# Deterministic pre-push gate mirroring the primary CI smoke surface.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"

node_prefix="$(brew --prefix node@22 2>/dev/null || true)"
[ -z "$node_prefix" ] || export PATH="$node_prefix/bin:$PATH"
python_prefix="$(brew --prefix python@3.12 2>/dev/null || true)"
[ -z "$python_prefix" ] || export PATH="$python_prefix/libexec/bin:$PATH"
python_bin="${SOLAR_PYTHON:-$repo/.venv/bin/python}"
[ -x "$python_bin" ] || {
    echo "missing .venv; run: bash scripts/bootstrap-macbook.sh" >&2
    exit 1
}

secret_scan() (
    scan_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai4research-gitleaks.XXXXXX")"
    trap 'find "$scan_dir" -depth -delete' EXIT
    git ls-files -z | tar --null -T - -cf - | tar -xf - -C "$scan_dir"
    gitleaks detect --no-git --source "$scan_dir" \
        --config "$repo/harness/gitleaks.toml" --redact --no-banner
)

echo "== AI4Research fast local gate =="
bash scripts/check-macbook-toolchain.sh
git diff --check
git diff --cached --check
bash scripts/check-privacy.sh
bash scripts/check-privacy.sh --self-test
secret_scan
bash scripts/check-release-coherence.sh
bash scripts/check-core-imports.sh
bash scripts/check-harness-plumbing.sh

"$python_bin" -m py_compile \
    harness/lib/graph_node_dispatcher.py \
    harness/lib/symphony/status-server.py \
    harness/scripts/tech_hotspot_radar.py

SOLAR_GRAPH_BUILDER_OPERATOR_POOL=0 "$python_bin" -m pytest -q \
    tests/test_version_metadata_sync.py \
    tests/test_ai4research_deployment_contract.py \
    tests/vertical/account_management/test_authentication_session_security_env_gated.py \
    harness/tests/test_status_server_fast_bind.py \
    tests/harness/graph/test_pm_inbox_closeout_reconcile.py \
    tests/harness/graph/test_graph_status_sync.py \
    tests/harness/graph/test_parent_ready_closeout.py \
    tests/harness/graph/test_task_graph_state_io.py \
    tests/harness/graph/test_graph_dispatch_lease_busy.py \
    tests/harness/graph/test_graph_dispatch_submit.py \
    tests/harness/graph/test_worker_assignment_reasons.py \
    tests/harness/test_eval_verdict_evidence_gate_wiring.py \
    tests/harness/test_pm_dispatch.py

echo "AI4Research fast local gate: PASS"
