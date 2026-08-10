#!/usr/bin/env bash
# Manage a token-free SSH tunnel from the MacBook to the loopback-only
# AI4Research status service on the Mac mini.
set -euo pipefail

action="${1:-status}"
host="${AI4RESEARCH_DEPLOY_HOST:-macmini}"
local_port="${AI4RESEARCH_LOCAL_PORT:-18875}"
remote_port="${AI4RESEARCH_REMOTE_PORT:-8875}"
socket="${AI4RESEARCH_TUNNEL_SOCKET:-$HOME/.ssh/ai4research-macmini.sock}"

case "$action" in start|stop|status) ;; *) echo "usage: scripts/ai4research-tunnel.sh start|stop|status" >&2; exit 2 ;; esac
case "$host" in *[!A-Za-z0-9._@-]*) echo "unsupported SSH host value" >&2; exit 2 ;; esac
for candidate in "$local_port" "$remote_port"; do
  case "$candidate" in ''|*[!0-9]*) echo "invalid tunnel port" >&2; exit 2 ;; esac
done

is_running() {
  ssh -S "$socket" -O check "$host" >/dev/null 2>&1
}

case "$action" in
  start)
    mkdir -p "$(dirname "$socket")"
    if ! is_running; then
      ssh -M -S "$socket" -fNT \
        -o BatchMode=yes \
        -o ExitOnForwardFailure=yes \
        -L "127.0.0.1:$local_port:127.0.0.1:$remote_port" \
        "$host"
    fi
    curl -fsS --connect-timeout 2 --max-time 5 "http://127.0.0.1:$local_port/healthz" >/dev/null
    echo "ok: http://127.0.0.1:$local_port/"
    ;;
  stop)
    if is_running; then
      ssh -S "$socket" -O exit "$host" >/dev/null
    fi
    echo "ok: tunnel stopped"
    ;;
  status)
    if is_running && curl -fsS --connect-timeout 2 --max-time 5 "http://127.0.0.1:$local_port/healthz" >/dev/null; then
      echo "ok: http://127.0.0.1:$local_port/"
    else
      echo "error: tunnel or remote health unavailable" >&2
      exit 1
    fi
    ;;
esac
