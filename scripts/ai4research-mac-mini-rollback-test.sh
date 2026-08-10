#!/usr/bin/env bash
# Deliberately activates an invalid synthetic release and proves automatic
# recovery of the previously healthy SHA.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
host="${AI4RESEARCH_DEPLOY_HOST:-macmini}"
remote_root="${AI4RESEARCH_REMOTE_ROOT:-}"
port="${AI4RESEARCH_REMOTE_PORT:-8875}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host) host="${2:?missing --host value}"; shift 2 ;;
    --root) remote_root="${2:?missing --root value}"; shift 2 ;;
    --port) port="${2:?missing --port value}"; shift 2 ;;
    -h|--help)
      echo "usage: scripts/ai4research-mac-mini-rollback-test.sh [--host HOST] [--root PATH] [--port PORT]"
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$host" in *[!A-Za-z0-9._@-]*) echo "unsupported SSH host value" >&2; exit 2 ;; esac
[ -n "$remote_root" ] || remote_root="$(ssh -o BatchMode=yes "$host" 'printf "%s" "$HOME"')/Services/AI4Research"
case "$remote_root" in /Users/*/Services/AI4Research) ;; *) echo "unsafe remote root: $remote_root" >&2; exit 2 ;; esac

ssh -o BatchMode=yes "$host" bash -s -- negative-control "$remote_root" unused unused "$port" \
  < "$repo/scripts/remote-ai4research-release.sh"
