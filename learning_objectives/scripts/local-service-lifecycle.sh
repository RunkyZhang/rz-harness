#!/usr/bin/env bash
set -u

service="${1:-}"
action="${2:-}"
state_dir="${SFA_LIFECYCLE_STATE_DIR:-${TMPDIR:-/tmp}/sfa-harness}"
maven_bin="${SFA_LIFECYCLE_MAVEN_BIN:-mvn}"
java_bin="${SFA_LIFECYCLE_JAVA_BIN:-java}"
curl_bin="${SFA_LIFECYCLE_CURL_BIN:-curl}"
ps_bin="${SFA_LIFECYCLE_PS_BIN:-ps}"
kill_bin="${SFA_LIFECYCLE_KILL_BIN:-kill}"
lsof_bin="${SFA_LIFECYCLE_LSOF_BIN:-lsof}"
sleep_bin="${SFA_LIFECYCLE_SLEEP_BIN:-sleep}"
stat_bin="${SFA_LIFECYCLE_STAT_BIN:-stat}"
date_bin="${SFA_LIFECYCLE_DATE_BIN:-date}"
log_file="$state_dir/${service:-unknown}.log"

emit_failure() {
  local phase="$1" message="$2" exit_code="${3:-1}"
  printf 'PHASE=%s\nSERVICE=%s\nMESSAGE=%s\nLOG=%s\n' \
    "$phase" "$service" "$message" "$log_file" >&2
  exit "$exit_code"
}

service_profile() {
  case "$service" in
    backend-sales-management)
      repo="${SFA_REPO_BACKEND_SALES_MANAGEMENT:-}"
      module="sfa-sales-management-interfaces"
      jar="$repo/$module/target/sfa-sales-management-interfaces-1.0-SNAPSHOT.jar"
      port="${SFA_LOCAL_BACKEND_SALES_MANAGEMENT_PORT:-31010}"
      health_url="http://127.0.0.1:$port/actuator/health"
      ;;
    *)
      emit_failure SERVICE_PROFILE "unsupported service: $service" 2
      ;;
  esac

  pid_file="$state_dir/$service.pid"
}

run_build() {
  [[ -d "$repo" ]] || emit_failure PRECHECK "repo not found: $repo"
  (cd "$repo" && "$maven_bin" -pl "$module" -am -DskipTests package) || \
    emit_failure PACKAGE "build failed"
  [[ -f "$jar" ]] || emit_failure PACKAGE "jar was not created: $jar"
}

pid_matches_target() {
  local command_line
  command_line="$("$ps_bin" -p "$1" -o command= 2>/dev/null || true)"
  [[ "$command_line" == *"$jar"* ]]
}

wait_for_exit() {
  local pid="$1" attempt
  for attempt in $(seq 1 30); do
    "$kill_bin" -0 "$pid" 2>/dev/null || return 0
    pid_matches_target "$pid" || return 0
    "$sleep_bin" 1
  done
  return 1
}

stop_owned_process() {
  [[ -f "$pid_file" ]] || return 0

  local pid
  pid="$(<"$pid_file")"
  pid_matches_target "$pid" || emit_failure STOP_OLD "pid file does not belong to target jar"
  "$kill_bin" -TERM "$pid" || emit_failure STOP_OLD "could not signal target process"
  wait_for_exit "$pid" || emit_failure STOP_OLD "process did not exit"
  rm -f "$pid_file"
}

start_process() {
  started_at="$("$date_bin" '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null)" || \
    emit_failure START "could not capture start time"
  [[ -n "$started_at" ]] || emit_failure START "could not capture start time"

  nohup "$java_bin" -jar "$jar" --server.port="$port" --spring.profiles.active=local \
    --spring.rabbitmq.listener.simple.auto-startup=false \
    --spring.rabbitmq.listener.direct.auto-startup=false \
    --management.health.rabbit.enabled=false \
    --spring.cloud.nacos.discovery.register-enabled=false \
    --xxl.job.admin.addresses= >"$log_file" 2>&1 &
  printf '%s\n' "$!" >"$pid_file"
}

read_jar_mtime() {
  jar_mtime="$("$stat_bin" -f %m "$jar" 2>/dev/null)" || \
    emit_failure PACKAGE "could not read jar modification time: $jar"
  [[ -n "$jar_mtime" ]] || emit_failure PACKAGE "could not read jar modification time: $jar"
}

port_listening() {
  "$lsof_bin" -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

wait_for_listener() {
  local attempt
  for attempt in $(seq 1 30); do
    port_listening "$port" && return 0
    "$sleep_bin" 1
  done
  emit_failure WAIT_LISTENER "service is not listening on port $port"
}

wait_for_health() {
  local body attempt
  for attempt in $(seq 1 30); do
    body="$("$curl_bin" -fsS --max-time 2 "$health_url" 2>/dev/null || true)"
    [[ "$body" == *'"status":"UP"'* ]] && return 0
    "$sleep_bin" 1
  done
  emit_failure WAIT_HEALTH "health endpoint did not report UP"
}

verify_started_process() {
  local pid
  pid="$(<"$pid_file")" || emit_failure CHECK_PROCESS "could not read PID file: $pid_file"
  "$kill_bin" -0 "$pid" 2>/dev/null || emit_failure CHECK_PROCESS "started process is not alive"
  pid_matches_target "$pid" || emit_failure CHECK_PROCESS "started process does not belong to target jar"
}

status_service() {
  [[ -f "$pid_file" ]] || emit_failure CHECK_PROCESS "PID file not found: $pid_file"

  local pid
  pid="$(<"$pid_file")"
  pid_matches_target "$pid" || emit_failure CHECK_PROCESS "pid file does not belong to target jar"
  port_listening "$port" || emit_failure CHECK_PROCESS "service is not listening on port $port"
  printf 'PHASE=CHECK_PROCESS\nSERVICE=%s\nPID=%s\nPORT=%s\nLOG=%s\n' \
    "$service" "$pid" "$port" "$log_file"
}

check_web_stack() {
  status_service
  port_listening "${SFA_HARNESS_PROXY_PORT:-19080}" || \
    emit_failure CHECK_PROXY "proxy is not listening"
  port_listening "${SFA_FRONTEND_MAP_SYSTEM_DEV_PORT:-9527}" || \
    emit_failure CHECK_FRONTEND "mapSystem is not listening"
  printf 'WEB_STACK=READY\n'
}

[[ -n "$action" ]] || emit_failure USAGE "missing action"
mkdir -p "$state_dir" || emit_failure PRECHECK "state directory cannot be created: $state_dir"

if [[ "$service" == "check-web-stack" ]]; then
  [[ "$action" == "--backend" && "${3:-}" == "backend-sales-management" ]] || \
    emit_failure CHECK_WEB_STACK "expected --backend backend-sales-management"
  service="backend-sales-management"
  log_file="$state_dir/$service.log"
  service_profile
  check_web_stack
  exit 0
fi

service_profile

case "$action" in
  build)
    run_build
    printf 'PHASE=PACKAGE\nSERVICE=%s\nJAR=%s\nLOG=%s\n' "$service" "$jar" "$log_file"
    ;;
  stop)
    stop_owned_process
    printf 'PHASE=STOPPED\nSERVICE=%s\nLOG=%s\n' "$service" "$log_file"
    ;;
  status)
    status_service
    ;;
  restart)
    run_build
    stop_owned_process
    start_process
    wait_for_listener
    wait_for_health
    verify_started_process
    read_jar_mtime
    printf 'PHASE=READY\nSERVICE=%s\nPID=%s\nPORT=%s\nJAR_MTIME=%s\nSTARTED_AT=%s\nHEALTH=UP\nLOG=%s\n' \
      "$service" "$(<"$pid_file")" "$port" "$jar_mtime" "$started_at" "$log_file"
    ;;
  *)
    emit_failure USAGE "unsupported action: $action"
    ;;
esac
