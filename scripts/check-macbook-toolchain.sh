#!/usr/bin/env bash
# Validate the local workstation against config/dev-toolchain.json.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
manifest="config/dev-toolchain.json"
fail=0

ok() { printf 'ok: %s\n' "$*"; }
bad() { printf 'FAIL: %s\n' "$*" >&2; fail=1; }

[ "$(uname -s)" = "Darwin" ] && ok "platform Darwin" || bad "platform must be Darwin"
[ "$(uname -m)" = "arm64" ] && ok "architecture arm64" || bad "architecture must be arm64"

python_bin=".venv/bin/python"
if [ ! -x "$python_bin" ]; then
    bad ".venv is missing; run: bash scripts/bootstrap-macbook.sh"
    exit 1
fi

expected="$($python_bin - "$manifest" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
print(
    data["python"]["series"],
    data["node"]["major"],
    data["bun"]["minimum_version"],
    data["codex"]["minimum_version"],
    sep="\t",
)
PY
)"
IFS=$'\t' read -r python_series node_major bun_minimum codex_minimum <<<"$expected"

actual_python="$($python_bin -c 'import platform; print(platform.python_version())')"
case "$actual_python" in
    "$python_series".*) ok "Python $actual_python" ;;
    *) bad "Python $actual_python does not match required series $python_series" ;;
esac

if command -v brew >/dev/null 2>&1; then
    node_prefix="$(brew --prefix node@22 2>/dev/null || true)"
else
    node_prefix=""
fi
if [ -n "$node_prefix" ] && [ -x "$node_prefix/bin/node" ]; then
    export PATH="$node_prefix/bin:$PATH"
fi

if command -v node >/dev/null 2>&1; then
    actual_node="$(node -p 'process.versions.node')"
    [ "${actual_node%%.*}" = "$node_major" ] && ok "Node $actual_node" \
        || bad "Node $actual_node does not match required major $node_major"
else
    bad "Node is missing"
fi

version_at_least() {
    "$python_bin" - "$1" "$2" <<'PY'
import re
import sys

def parts(value):
    return tuple(int(item) for item in re.findall(r"\d+", value)[:3])

raise SystemExit(0 if parts(sys.argv[1]) >= parts(sys.argv[2]) else 1)
PY
}

if command -v bun >/dev/null 2>&1; then
    actual_bun="$(bun --version)"
    version_at_least "$actual_bun" "$bun_minimum" && ok "Bun $actual_bun" \
        || bad "Bun $actual_bun is older than $bun_minimum"
else
    bad "Bun is missing"
fi

if command -v codex >/dev/null 2>&1; then
    actual_codex="$(codex --version | awk '{print $NF}')"
    version_at_least "$actual_codex" "$codex_minimum" && ok "Codex $actual_codex" \
        || bad "Codex $actual_codex is older than $codex_minimum"
else
    bad "Codex is missing"
fi

for command_name in git jq tmux bash shellcheck gitleaks uv; do
    command -v "$command_name" >/dev/null 2>&1 && ok "$command_name available" \
        || bad "$command_name is missing"
done

[ -x node_modules/.bin/tsc ] && ok "root Bun dependencies installed" \
    || bad "root Bun dependencies missing; run bootstrap-macbook"

if [ "$fail" -ne 0 ]; then
    echo "MacBook toolchain: FAIL" >&2
    exit 1
fi
echo "MacBook toolchain: PASS"
