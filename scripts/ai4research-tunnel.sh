#!/usr/bin/env bash
# Manage a persistent, token-free SSH tunnel from the MacBook to the
# loopback-only AI4Research status service on the Mac mini.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
action="${1:-status}"
host="${AI4RESEARCH_DEPLOY_HOST:-macmini}"
local_port="${AI4RESEARCH_LOCAL_PORT:-18875}"
remote_port="${AI4RESEARCH_REMOTE_PORT:-8875}"
label="com.ai4research.solar.tunnel"
uid="$(id -u)"
domain="gui/$uid"
plist="$HOME/Library/LaunchAgents/$label.plist"
template="$repo/deploy/ai4research/$label.plist.template"
log_dir="$HOME/Library/Logs/AI4Research"
legacy_socket="${AI4RESEARCH_TUNNEL_SOCKET:-$HOME/.ssh/ai4research-macmini.sock}"

case "$action" in start|stop|status) ;; *) echo "usage: scripts/ai4research-tunnel.sh start|stop|status" >&2; exit 2 ;; esac
case "$host" in *[!A-Za-z0-9._@-]*) echo "unsupported SSH host value" >&2; exit 2 ;; esac
for candidate in "$local_port" "$remote_port"; do
  case "$candidate" in ''|*[!0-9]*) echo "invalid tunnel port" >&2; exit 2 ;; esac
done

legacy_running() {
  ssh -S "$legacy_socket" -O check "$host" >/dev/null 2>&1
}

agent_loaded() {
  launchctl print "$domain/$label" >/dev/null 2>&1
}

health_ok() {
  curl -fsS --connect-timeout 2 --max-time 5 "http://127.0.0.1:$local_port/healthz" >/dev/null
}

stop_legacy_tunnel() {
  if legacy_running; then
    ssh -S "$legacy_socket" -O exit "$host" >/dev/null 2>&1 || true
  fi
  [ ! -S "$legacy_socket" ] || unlink "$legacy_socket"
}

render_plist() {
  local tmp="$plist.tmp.$$"
  [ -f "$template" ] || { echo "missing tunnel template: $template" >&2; return 1; }
  mkdir -p "$(dirname "$plist")" "$log_dir"
  sed \
    -e "s|__LABEL__|$label|g" \
    -e "s|__HOST__|$host|g" \
    -e "s|__LOCAL_PORT__|$local_port|g" \
    -e "s|__REMOTE_PORT__|$remote_port|g" \
    -e "s|__USER_HOME__|$HOME|g" \
    -e "s|__LOG_DIR__|$log_dir|g" \
    "$template" > "$tmp"
  plutil -lint "$tmp" >/dev/null
  mv -f "$tmp" "$plist"
}

case "$action" in
  start)
    stop_legacy_tunnel
    launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      agent_loaded || break
      sleep 0.25
    done
    if agent_loaded; then
      echo "error: previous tunnel agent did not unload" >&2
      exit 1
    fi
    render_plist
    launchctl enable "$domain/$label"
    bootstrapped=false
    for _ in $(seq 1 12); do
      if launchctl bootstrap "$domain" "$plist"; then
        bootstrapped=true
        break
      fi
      sleep 0.5
    done
    if [ "$bootstrapped" != true ]; then
      echo "error: persistent tunnel launchd bootstrap failed" >&2
      exit 1
    fi
    launchctl kickstart -k "$domain/$label"
    for _ in $(seq 1 20); do
      if agent_loaded && health_ok; then
        echo "ok: persistent tunnel http://127.0.0.1:$local_port/"
        exit 0
      fi
      sleep 0.5
    done
    echo "error: persistent tunnel failed health check" >&2
    exit 1
    ;;
  stop)
    stop_legacy_tunnel
    launchctl disable "$domain/$label" >/dev/null 2>&1 || true
    launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
    echo "ok: tunnel stopped and disabled"
    ;;
  status)
    if agent_loaded && health_ok; then
      echo "ok: persistent tunnel http://127.0.0.1:$local_port/"
    else
      echo "error: persistent tunnel or remote health unavailable" >&2
      exit 1
    fi
    ;;
esac
