#!/usr/bin/env bash
# Remote half of the commit-addressed AI4Research deployment contract.
# This script is streamed over SSH by deploy-ai4research-mac-mini.sh.
set -euo pipefail

mode="${1:-}"
root="${2:-}"
sha="${3:-}"
archive_sha="${4:-}"
port="${5:-8875}"

usage() {
  echo "usage: remote-ai4research-release.sh deploy|negative-control|status ROOT SHA ARCHIVE_SHA PORT" >&2
  exit 2
}

case "$mode" in
  deploy|negative-control|status) ;;
  *) usage ;;
esac
case "$root" in
  /Users/*/Services/AI4Research) ;;
  *) echo "refusing unsafe AI4Research root: $root" >&2; exit 2 ;;
esac
case "$root" in
  *[!A-Za-z0-9._/-]*) echo "unsupported character in deployment root" >&2; exit 2 ;;
esac
case "$port" in
  ''|*[!0-9]*) echo "invalid status port: $port" >&2; exit 2 ;;
esac
[ "$port" -ge 1024 ] && [ "$port" -le 65535 ] || {
  echo "status port must be between 1024 and 65535" >&2
  exit 2
}

label="com.ai4research.solar.status-server"
user_home="${root%/Services/AI4Research}"
uid="$(id -u)"
if launchctl print "gui/$uid" >/dev/null 2>&1; then
  launch_domain="gui/$uid"
else
  launch_domain="user/$uid"
fi
plist="$root/config/$label.plist"
run_dir="$root/shared/harness/run"
evidence_dir="$root/evidence/deployments"
python_bin="$(command -v python3 || true)"

require_runtime_tools() {
  [ -n "$python_bin" ] || { echo "python3 is required" >&2; return 1; }
  command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; return 1; }
  command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; return 1; }
  command -v shasum >/dev/null 2>&1 || { echo "shasum is required" >&2; return 1; }
}

current_sha() {
  local manifest="$root/current/.solar-release.json"
  [ -f "$manifest" ] || return 0
  jq -r '.commit_sha // empty' "$manifest" 2>/dev/null || true
}

atomic_link() {
  local relative_target="$1"
  local link_path="$2"
  local next_link="$root/.link-next.$$.${RANDOM}"
  ln -s "$relative_target" "$next_link"
  # BSD mv follows a destination symlink to a directory unless -h is used.
  # Without -h the temporary link lands inside the old release and activation
  # silently does not happen.
  mv -h -f "$next_link" "$link_path"
  [ "$(readlink "$link_path")" = "$relative_target" ] || {
    echo "atomic link verification failed: $link_path" >&2
    return 1
  }
}

write_plist() {
  local plist_tmp="$plist.tmp.$$"
  local template="$root/current/deploy/ai4research/com.ai4research.solar.status-server.plist.template"
  [ -f "$template" ] || return 1
  mkdir -p "$root/config" "$root/logs" "$root/runtime-home" "$run_dir"
  if ! sed \
    -e "s|__LABEL__|$label|g" \
    -e "s|__PYTHON__|$python_bin|g" \
    -e "s|__ROOT__|$root|g" \
    -e "s|__USER_HOME__|$user_home|g" \
    -e "s|__PORT__|$port|g" \
    "$template" > "$plist_tmp"; then
    [ ! -e "$plist_tmp" ] || unlink "$plist_tmp"
    return 1
  fi
  if ! plutil -lint "$plist_tmp" >/dev/null; then
    unlink "$plist_tmp"
    return 1
  fi
  mv -f "$plist_tmp" "$plist" || return 1
}

clear_runtime_markers() {
  for marker in status-server.pid status-server.port status-server.token; do
    [ ! -e "$run_dir/$marker" ] || unlink "$run_dir/$marker"
  done
}

restart_service() {
  local bootstrapped=false
  launchctl bootout "$launch_domain/$label" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    if ! launchctl print "$launch_domain/$label" >/dev/null 2>&1; then
      break
    fi
    sleep 0.25
  done
  launchctl print "$launch_domain/$label" >/dev/null 2>&1 && return 1
  clear_runtime_markers || return 1
  write_plist || return 1
  for _ in $(seq 1 12); do
    if launchctl bootstrap "$launch_domain" "$plist" >/dev/null 2>&1; then
      bootstrapped=true
      break
    fi
    sleep 0.5
  done
  [ "$bootstrapped" = true ] || return 1
  launchctl kickstart -k "$launch_domain/$label" >/dev/null || return 1
}

wait_for_health() {
  local attempts="${1:-40}"
  local discovered_port=""
  for _ in $(seq 1 "$attempts"); do
    if [ -f "$run_dir/status-server.port" ]; then
      discovered_port="$(tr -cd '0-9' < "$run_dir/status-server.port")"
    fi
    if [ "$discovered_port" = "$port" ] && \
      curl -fsS --connect-timeout 1 --max-time 3 "http://127.0.0.1:$port/healthz" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

write_record() {
  local status="$1"
  local requested_sha="$2"
  local previous_sha="$3"
  local active_sha="$4"
  local reason="$5"
  local stamp record
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  record="$evidence_dir/$stamp-$status-$requested_sha.json"
  mkdir -p "$evidence_dir"
  jq -n \
    --arg schema_version "ai4research.deployment-record.v1" \
    --arg status "$status" \
    --arg requested_sha "$requested_sha" \
    --arg previous_sha "$previous_sha" \
    --arg active_sha "$active_sha" \
    --arg reason "$reason" \
    --arg root "$root" \
    --arg label "$label" \
    --arg domain "$launch_domain" \
    --arg port "$port" \
    --arg recorded_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$schema_version,status:$status,requested_sha:$requested_sha,previous_sha:$previous_sha,active_sha:$active_sha,reason:$reason,root:$root,launchd:{label:$label,domain:$domain},health:{host:"127.0.0.1",port:($port|tonumber),path:"/healthz"},recorded_at:$recorded_at}' \
    > "$record"
  printf '%s\n' "$record"
}

prepare_release() {
  local incoming="$root/incoming/$sha.tar.gz"
  local release="$root/releases/$sha"
  local staging="$root/incoming/.staging-$sha-$$"
  local actual_archive_sha

  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || {
    echo "commit SHA must be 40 lowercase hex characters" >&2
    return 2
  }
  [[ "$archive_sha" =~ ^[0-9a-f]{64}$ ]] || {
    echo "archive SHA-256 is invalid" >&2
    return 2
  }

  mkdir -p "$root/incoming" "$root/releases" "$root/shared/harness" "$root/evidence/deployments"
  if [ -d "$release" ]; then
    [ -f "$release/.solar-release.json" ] || {
      echo "existing release has no manifest: $release" >&2
      return 1
    }
    [ "$(jq -r '.commit_sha // empty' "$release/.solar-release.json")" = "$sha" ] || {
      echo "existing release manifest SHA mismatch" >&2
      return 1
    }
    return 0
  fi
  [ -f "$incoming" ] || { echo "incoming archive missing: $incoming" >&2; return 1; }
  actual_archive_sha="$(shasum -a 256 "$incoming" | awk '{print $1}')"
  [ "$actual_archive_sha" = "$archive_sha" ] || {
    echo "archive checksum mismatch" >&2
    return 1
  }
  tar -tzf "$incoming" | awk '
    /^\// { bad=1 }
    /(^|\/)\.\.(\/|$)/ { bad=1 }
    END { exit bad }
  ' || { echo "archive contains an unsafe path" >&2; return 1; }

  mkdir -p "$staging"
  tar -xzf "$incoming" -C "$staging"
  [ -f "$staging/VERSION" ] || { echo "release is missing VERSION" >&2; return 1; }
  [ -f "$staging/harness/lib/symphony/status-server.py" ] || {
    echo "release is missing status-server.py" >&2
    return 1
  }
  [ -f "$staging/deploy/ai4research/com.ai4research.solar.status-server.plist.template" ] || {
    echo "release is missing launchd template" >&2
    return 1
  }

  for runtime_dir in run state logs cache sprints intents runs; do
    mkdir -p "$root/shared/harness/$runtime_dir"
    if [ -e "$staging/harness/$runtime_dir" ]; then
      find "$staging/harness/$runtime_dir" -depth -delete
    fi
    ln -s "$root/shared/harness/$runtime_dir" "$staging/harness/$runtime_dir"
  done

  jq -n \
    --arg schema_version "ai4research.release.v1" \
    --arg commit_sha "$sha" \
    --arg archive_sha256 "$archive_sha" \
    --arg version "$(tr -d '\r\n' < "$staging/VERSION")" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$schema_version,commit_sha:$commit_sha,archive_sha256:$archive_sha256,version:$version,created_at:$created_at}' \
    > "$staging/.solar-release.json"
  mv "$staging" "$release"
}

deploy_release() {
  local previous active record
  require_runtime_tools
  prepare_release
  previous="$(current_sha)"
  atomic_link "releases/$sha" "$root/current"
  if [ -n "$previous" ] && [ "$previous" != "$sha" ]; then
    atomic_link "releases/$previous" "$root/previous"
  fi

  if restart_service && wait_for_health 60; then
    active="$(current_sha)"
    record="$(write_record deployed "$sha" "$previous" "$active" "health_check_passed")"
    [ ! -f "$root/incoming/$sha.tar.gz" ] || unlink "$root/incoming/$sha.tar.gz"
    jq -n --arg status ok --arg sha "$active" --arg previous "$previous" --arg record "$record" --arg port "$port" \
      '{status:$status,commit_sha:$sha,previous_sha:$previous,record:$record,health_url:("http://127.0.0.1:"+$port+"/healthz")}'
    return 0
  fi

  launchctl bootout "$launch_domain/$label" >/dev/null 2>&1 || true
  if [ -n "$previous" ] && [ -d "$root/releases/$previous" ]; then
    atomic_link "releases/$previous" "$root/current"
    if restart_service && wait_for_health 60; then
      record="$(write_record rolled_back "$sha" "$previous" "$previous" "activation_health_failed")"
      echo "deployment failed; restored previous release $previous; record=$record" >&2
      return 1
    fi
    write_record rollback_failed "$sha" "$previous" "$(current_sha)" "activation_and_rollback_health_failed" >/dev/null
    echo "deployment and rollback health checks failed" >&2
    return 1
  fi

  [ ! -L "$root/current" ] || unlink "$root/current"
  write_record activation_failed "$sha" "" "" "first_activation_health_failed" >/dev/null
  echo "first deployment failed health; no current release remains active" >&2
  return 1
}

negative_control() {
  local before synthetic_id synthetic_dir record
  require_runtime_tools
  before="$(current_sha)"
  [ -n "$before" ] || { echo "negative control requires a healthy current release" >&2; return 1; }
  wait_for_health 5 || { echo "current release is not healthy before negative control" >&2; return 1; }
  synthetic_id="negative-control-$(date -u +%Y%m%dT%H%M%SZ)"
  synthetic_dir="$root/releases/$synthetic_id"
  mkdir -p "$synthetic_dir"
  jq -n --arg schema_version "ai4research.negative-release.v1" --arg commit_sha "$synthetic_id" \
    '{schema_version:$schema_version,commit_sha:$commit_sha,purpose:"rollback-negative-control"}' \
    > "$synthetic_dir/.solar-release.json"

  atomic_link "releases/$synthetic_id" "$root/current"
  if restart_service && wait_for_health 8; then
    atomic_link "releases/$before" "$root/current"
    restart_service || true
    wait_for_health 60 || true
    write_record negative_control_failed "$synthetic_id" "$before" "$(current_sha)" "invalid_release_became_healthy" >/dev/null
    echo "negative control unexpectedly became healthy" >&2
    return 1
  fi

  atomic_link "releases/$before" "$root/current"
  restart_service
  wait_for_health 60 || {
    write_record rollback_failed "$synthetic_id" "$before" "$(current_sha)" "negative_control_restore_unhealthy" >/dev/null
    echo "negative-control rollback did not restore health" >&2
    return 1
  }
  record="$(write_record rollback_proven "$synthetic_id" "$before" "$before" "negative_control_health_failed_and_previous_restored")"
  jq -n --arg status ok --arg restored_sha "$before" --arg negative_release "$synthetic_id" --arg record "$record" --arg port "$port" \
    '{status:$status,rollback:"proven",restored_sha:$restored_sha,negative_release:$negative_release,record:$record,health_url:("http://127.0.0.1:"+$port+"/healthz")}'
}

status_payload() {
  local active="" previous="" launchd_status="error" health_status="error" latest_record=""
  active="$(current_sha)"
  if [ -f "$root/previous/.solar-release.json" ]; then
    previous="$(jq -r '.commit_sha // empty' "$root/previous/.solar-release.json" 2>/dev/null || true)"
  fi
  if launchctl print "$launch_domain/$label" >/dev/null 2>&1; then
    launchd_status="ok"
  fi
  if curl -fsS --connect-timeout 1 --max-time 3 "http://127.0.0.1:$port/healthz" >/dev/null 2>&1; then
    health_status="ok"
  fi
  latest_record="$(find "$evidence_dir" -maxdepth 1 -type f -name '*.json' -print 2>/dev/null | sort | tail -1)"
  jq -n \
    --arg status "$([ "$launchd_status" = ok ] && [ "$health_status" = ok ] && echo ok || echo error)" \
    --arg active_sha "$active" \
    --arg previous_sha "$previous" \
    --arg launchd "$launchd_status" \
    --arg health "$health_status" \
    --arg latest_record "$latest_record" \
    --arg root "$root" \
    --arg label "$label" \
    --arg domain "$launch_domain" \
    --arg port "$port" \
    '{status:$status,root:$root,active_sha:$active_sha,previous_sha:$previous_sha,launchd:{status:$launchd,label:$label,domain:$domain},health:{status:$health,url:("http://127.0.0.1:"+$port+"/healthz")},latest_record:$latest_record}'
  [ "$launchd_status" = ok ] && [ "$health_status" = ok ]
}

case "$mode" in
  deploy) deploy_release ;;
  negative-control) negative_control ;;
  status) require_runtime_tools; status_payload ;;
esac
