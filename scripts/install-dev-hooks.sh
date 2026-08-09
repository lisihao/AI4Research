#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
git config --local core.hooksPath .githooks
echo "installed repository-local Git hooks: .githooks"
