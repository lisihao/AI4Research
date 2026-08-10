#!/usr/bin/env bash
# Package a committed AI4Research tree, transfer it to the Mac mini, and
# atomically activate it by full commit SHA.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
host="${AI4RESEARCH_DEPLOY_HOST:-macmini}"
remote_root="${AI4RESEARCH_REMOTE_ROOT:-}"
sha="HEAD"
port="${AI4RESEARCH_REMOTE_PORT:-8875}"
run_gate=true

usage() {
  cat <<'EOF'
usage: scripts/deploy-ai4research-mac-mini.sh [options]

  --host HOST       SSH host alias (default: macmini)
  --root PATH       Mac mini deployment root
  --sha REV         committed revision to deploy (default: HEAD)
  --port PORT       loopback status port on Mac mini (default: 8875)
  --no-local-gate   skip the fast local gate (must be an explicit choice)
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host) host="${2:?missing --host value}"; shift 2 ;;
    --root) remote_root="${2:?missing --root value}"; shift 2 ;;
    --sha) sha="${2:?missing --sha value}"; shift 2 ;;
    --port) port="${2:?missing --port value}"; shift 2 ;;
    --no-local-gate) run_gate=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$host" in *[!A-Za-z0-9._@-]*) echo "unsupported SSH host value" >&2; exit 2 ;; esac
[ -n "$remote_root" ] || remote_root="$(ssh -o BatchMode=yes "$host" 'printf "%s" "$HOME"')/Services/AI4Research"
case "$remote_root" in /Users/*/Services/AI4Research) ;; *) echo "unsafe remote root: $remote_root" >&2; exit 2 ;; esac
case "$remote_root" in *[!A-Za-z0-9._/-]*) echo "unsupported character in remote root" >&2; exit 2 ;; esac
case "$port" in ''|*[!0-9]*) echo "invalid port: $port" >&2; exit 2 ;; esac

cd "$repo"
full_sha="$(git rev-parse --verify "$sha^{commit}")"
[ "${#full_sha}" -eq 40 ] || { echo "could not resolve a full commit SHA" >&2; exit 1; }
if [ "$run_gate" = true ]; then
  bash scripts/test-local-fast.sh
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai4research-deploy.XXXXXX")"
cleanup() {
  find "$tmp_dir" -depth -delete
}
trap cleanup EXIT
archive="$tmp_dir/$full_sha.tar.gz"
git archive --format=tar "$full_sha" | gzip -n > "$archive"
archive_sha="$(shasum -a 256 "$archive" | awk '{print $1}')"

ssh -o BatchMode=yes "$host" "mkdir -p '$remote_root/incoming'"
scp -q "$archive" "$host:$remote_root/incoming/$full_sha.tar.gz"
ssh -o BatchMode=yes "$host" bash -s -- deploy "$remote_root" "$full_sha" "$archive_sha" "$port" \
  < "$repo/scripts/remote-ai4research-release.sh"
