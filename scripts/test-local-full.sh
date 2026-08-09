#!/usr/bin/env bash
# Full developer gate: fast pre-push checks plus platform-available UI/Desktop gates.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"

node_prefix="$(brew --prefix node@22 2>/dev/null || true)"
[ -z "$node_prefix" ] || export PATH="$node_prefix/bin:$PATH"
python_prefix="$(brew --prefix python@3.12 2>/dev/null || true)"
[ -z "$python_prefix" ] || export PATH="$python_prefix/libexec/bin:$PATH"

bash scripts/test-local-fast.sh
bash scripts/test-local.sh
echo "AI4Research full local gate: PASS"
