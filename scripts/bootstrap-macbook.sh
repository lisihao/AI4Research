#!/usr/bin/env bash
# Reproducible AI4Research developer bootstrap for Apple Silicon macOS.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"

full=0
install_hooks=1
for arg in "$@"; do
    case "$arg" in
        --full) full=1 ;;
        --skip-hooks) install_hooks=0 ;;
        -h|--help)
            echo "usage: $0 [--full] [--skip-hooks]"
            exit 0
            ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

[ "$(uname -s)" = "Darwin" ] || {
    echo "bootstrap-macbook requires macOS" >&2
    exit 1
}
[ "$(uname -m)" = "arm64" ] || {
    echo "bootstrap-macbook currently supports Apple Silicon (arm64)" >&2
    exit 1
}

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "missing required command: $1" >&2
        return 1
    }
}

for command_name in brew uv bun git; do
    require "$command_name"
done

python_bin="${SOLAR_PYTHON:-}"
if [ -z "$python_bin" ]; then
    python_bin="$(brew --prefix python@3.12)/bin/python3.12"
fi
[ -x "$python_bin" ] || {
    echo "Python 3.12 not found; run: brew install python@3.12" >&2
    exit 1
}
python_prefix="$(brew --prefix python@3.12)"
export PATH="$python_prefix/libexec/bin:$PATH"

node_prefix="$(brew --prefix node@22 2>/dev/null || true)"
[ -n "$node_prefix" ] && [ -x "$node_prefix/bin/node" ] || {
    echo "Node 22 not found; run: brew install node@22" >&2
    exit 1
}
export PATH="$node_prefix/bin:$PATH"

echo "== Python environment =="
uv venv --clear --python "$python_bin" .venv
uv pip sync --python .venv/bin/python requirements/dev.lock.txt

echo "== Bun dependencies =="
bun install --frozen-lockfile

if [ "$full" -eq 1 ]; then
    echo "== Dashboard dependencies =="
    (cd harness/status-server/react-app && npm ci)
    echo "== Desktop dependencies =="
    (cd desktop && npm ci)
    echo "== Playwright Chromium =="
    (cd desktop && npx playwright install chromium)
fi

if [ "$install_hooks" -eq 1 ]; then
    bash scripts/install-dev-hooks.sh
fi

bash scripts/check-macbook-toolchain.sh
echo "MacBook bootstrap complete"
