#!/usr/bin/env bash
# Read-only AI4Research release/service status from the Mac mini.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
host="${AI4RESEARCH_DEPLOY_HOST:-macmini}"
remote_root="${AI4RESEARCH_REMOTE_ROOT:-}"
port="${AI4RESEARCH_REMOTE_PORT:-8875}"
json=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host) host="${2:?missing --host value}"; shift 2 ;;
    --root) remote_root="${2:?missing --root value}"; shift 2 ;;
    --port) port="${2:?missing --port value}"; shift 2 ;;
    --json) json=true; shift ;;
    -h|--help)
      echo "usage: scripts/ai4research-mac-mini-status.sh [--host HOST] [--root PATH] [--port PORT] [--json]"
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$host" in *[!A-Za-z0-9._@-]*) echo "unsupported SSH host value" >&2; exit 2 ;; esac
[ -n "$remote_root" ] || remote_root="$(ssh -o BatchMode=yes "$host" 'printf "%s" "$HOME"')/Services/AI4Research"
case "$remote_root" in /Users/*/Services/AI4Research) ;; *) echo "unsafe remote root: $remote_root" >&2; exit 2 ;; esac

payload="$(ssh -o BatchMode=yes "$host" bash -s -- status "$remote_root" unused unused "$port" \
  < "$repo/scripts/remote-ai4research-release.sh")"
if [ "$json" = true ]; then
  printf '%s\n' "$payload"
  exit 0
fi

jq -r '
  "┌──────────────────────┬─────────┬──────────────────────────────────────────┐",
  "│ 项目                 │ 状态    │ 值                                       │",
  "├──────────────────────┼─────────┼──────────────────────────────────────────┤",
  ("│ AI4Research active   │ " + (.status|.[0:7]) + (" " * (7-(.status|length))) + " │ " + (.active_sha // "N/A" | .[0:40]) + (" " * (40-((.active_sha // "N/A")|length))) + " │"),
  ("│ launchd              │ " + (.launchd.status|.[0:7]) + (" " * (7-(.launchd.status|length))) + " │ " + (.launchd.label|.[0:40]) + (" " * (40-(.launchd.label|length))) + " │"),
  ("│ health               │ " + (.health.status|.[0:7]) + (" " * (7-(.health.status|length))) + " │ " + (.health.url|.[0:40]) + (" " * (40-(.health.url|length))) + " │"),
  "└──────────────────────┴─────────┴──────────────────────────────────────────┘",
  ("evidence=" + (.latest_record // "N/A"))
' <<< "$payload"
