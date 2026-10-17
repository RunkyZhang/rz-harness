#!/usr/bin/env bash
set -u

service="${1:-}"
action="${2:-}"
state_dir="${RZ_LIFECYCLE_STATE_DIR:-${TMPDIR:-/tmp}/sfa-harness}"
maven_bin="${RZ_BACKEND_MAVEN_COMMAND:-${RZ_LIFECYCLE_MAVEN_BIN:-mvn}}"
java_bin="${RZ_LIFECYCLE_JAVA_BIN:-java}"
curl_bin="${RZ_LIFECYCLE_CURL_BIN:-curl}"
ps_bin="${RZ_LIFECYCLE_PS_BIN:-ps}"
kill_bin="${RZ_LIFECYCLE_KILL_BIN:-kill}"
lsof_bin="${RZ_LIFECYCLE_LSOF_BIN:-lsof}"
sleep_bin="${RZ_LIFECYCLE_SLEEP_BIN:-sleep}"
stat_bin="${RZ_LIFECYCLE_STAT_BIN:-stat}"
date_bin="${RZ_LIFECYCLE_DATE_BIN:-date}"
log_file="$state_dir/${service:-unknown}.log"

emit_failure() {
  local phase="$1" message="$2" exit_code="${3:-1}"
  printf 'PHASE=%s\nSERVICE=%s\nMESSAGE=%s\nLOG=%s\n' \
    "$phase" "$service" "$message" "$log_file" >&2
  exit "$exit_code"
}

# 服务名 -> repo / 启动模块 / 端口。jar 由 resolve_jar_* 动态解析，不写死版本。
service_profile() {
  case "$service" in
    backend-sales-management)
      repo="${RZ_REPO_SFA_SALES_MANAGEMENT:-}"
      module="sfa-sales-management-interfaces"
      port="${RZ_LOCAL_BACKEND_SALES_MANAGEMENT_PORT:-31010}"
      ;;
    backend-sfa-backend)
      repo="${RZ_REPO_SFA_BACKEND:-}"
      module="wantwant-sfa-backend-webapi"
      port="${RZ_LOCAL_BACKEND_SFA_BACKEND_PORT:-9171}"
      ;;
    backend-sfa-root)
      repo="${RZ_REPO_SFA_ROOT:-}"
      module="wantwant-sfa-root-webapi"
      port="${RZ_LOCAL_BACKEND_SFA_ROOT_PORT:-9170}"
      ;;
    backend-sfa-base)
      repo="${RZ_REPO_SFA_BASE:-}"
      module="sfa-base-interfaces"
      port="${RZ_LOCAL_BACKEND_SFA_BASE_PORT:-34040}"
      ;;
    backend-sfa-data-fusion)
      repo="${RZ_REPO_SFA_DATA_FUSION:-}"
      module="sfa-data-fusion-interfaces"
      port="${RZ_LOCAL_BACKEND_SFA_DATA_FUSION_PORT:-32020}"
      ;;
    backend-arch-open)
      repo="${RZ_REPO_ARCH_OPEN:-}"
      module="arch-open-interfaces"
      port="${RZ_LOCAL_BACKEND_ARCH_OPEN_PORT:-41010}"
      ;;
    backend-arch-event)
      repo="${RZ_REPO_ARCH_EVENT:-}"
      module="arch-event-interfaces"
      port="${RZ_LOCAL_BACKEND_ARCH_EVENT_PORT:-43030}"
      ;;
    backend-arch-notification)
      repo="${RZ_REPO_ARCH_NOTIFICATION:-}"
      module="arch-notification-interfaces"
      port="${RZ_LOCAL_BACKEND_ARCH_NOTIFICATION_PORT:-42020}"
      ;;
    *)
      emit_failure SERVICE_PROFILE "unsupported service: $service" 2
      ;;
  esac

  health_url="http://127.0.0.1:$port/actuator/health"
  pid_file="$state_dir/$service.pid"
  jar=""
}

# 构建 JDK：按 repo 名取 RZ_JAVA_HOME_<REPO_ID>，回退 RZ_BACKEND_JAVA_HOME
resolve_java_home() {
  local repo_key java_home_var
  repo_key="$(basename "$repo" | tr '[:lower:]-' '[:upper:]_')"
  java_home_var="RZ_JAVA_HOME_${repo_key}"
  java_home="${!java_home_var:-${RZ_BACKEND_JAVA_HOME:-}}"
}

# 在 target 下找启动 jar（排除 sources/javadoc）。
resolve_jar_if_exists() {
  local target="$repo/$module/target"
  jar=""
  [[ -d "$target" ]] || return 0
  jar="$(find "$target" -maxdepth 1 -name "${module}-*.jar" \
    ! -name "*-sources.jar" ! -name "*-javadoc.jar" 2>/dev/null | head -1)"
}

resolve_jar() {
  resolve_jar_if_exists
  [[ -n "$jar" ]] || emit_failure PACKAGE "jar was not found under $repo/$module/target"
}

run_build() {
  [[ -d "$repo" ]] || emit_failure PRECHECK "repo not found: $repo"
  resolve_java_home
  local -a maven_args=()
  if [[ -n "${RZ_BACKEND_MAVEN_ARGS:-}" ]]; then
    read -r -a maven_args <<< "${RZ_BACKEND_MAVEN_ARGS}"
  fi
  if [[ -n "$java_home" ]]; then
    (cd "$repo" && JAVA_HOME="$java_home" PATH="$java_home/bin:$PATH" \
      "$maven_bin" "${maven_args[@]}" -pl "$module" -am -DskipTests package) || \
      emit_failure PACKAGE "build failed"
  else
    (cd "$repo" && "$maven_bin" "${maven_args[@]}" -pl "$module" -am -DskipTests package) || \
      emit_failure PACKAGE "build failed"
  fi
  resolve_jar
}

pid_matches_target() {
  local command_line
  command_line="$("$ps_bin" -p "$1" -o command= 2>/dev/null || true)"
  [[ -n "$jar" && "$command_line" == *"$jar"* ]]
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

  resolve_jar_if_exists
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

  resolve_java_home
  local java_opts="${RZ_BACKEND_JAVA_OPTS:-}"
  local profile="${RZ_BACKEND_SPRING_PROFILE:-local}"

  # java_opts 故意不加引号，按空格拆成多个 JVM 参数。
  if [[ -n "$java_home" ]]; then
    nohup env JAVA_HOME="$java_home" PATH="$java_home/bin:$PATH" \
      "$java_bin" $java_opts -jar "$jar" --server.port="$port" --spring.profiles.active="$profile" \
      --spring.rabbitmq.listener.simple.auto-startup=false \
      --spring.rabbitmq.listener.direct.auto-startup=false \
      --management.health.rabbit.enabled=false \
      --xxl.job.admin.addresses= >"$log_file" 2>&1 &
  else
    nohup "$java_bin" $java_opts -jar "$jar" --server.port="$port" --spring.profiles.active="$profile" \
      --spring.rabbitmq.listener.simple.auto-startup=false \
      --spring.rabbitmq.listener.direct.auto-startup=false \
      --management.health.rabbit.enabled=false \
      --xxl.job.admin.addresses= >"$log_file" 2>&1 &
  fi
  printf '%s\n' "$!" >"$pid_file"
}

read_jar_mtime() {
  jar_mtime="$("$stat_bin" -f %m "$jar" 2>/dev/null || "$stat_bin" -c %Y "$jar" 2>/dev/null)" || \
    emit_failure PACKAGE "could not read jar modification time: $jar"
  [[ -n "$jar_mtime" ]] || emit_failure PACKAGE "could not read jar modification time: $jar"
}

port_listening() {
  "$lsof_bin" -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

wait_for_listener() {
  local attempt
  for attempt in $(seq 1 120); do
    port_listening "$port" && return 0
    "$sleep_bin" 1
  done
  emit_failure WAIT_LISTENER "service is not listening on port $port"
}

wait_for_health() {
  local body attempt
  for attempt in $(seq 1 120); do
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

  resolve_jar_if_exists
  local pid
  pid="$(<"$pid_file")"
  pid_matches_target "$pid" || emit_failure CHECK_PROCESS "pid file does not belong to target jar"
  port_listening "$port" || emit_failure CHECK_PROCESS "service is not listening on port $port"
  printf 'PHASE=CHECK_PROCESS\nSERVICE=%s\nPID=%s\nPORT=%s\nLOG=%s\n' \
    "$service" "$pid" "$port" "$log_file"
}

check_web_stack() {
  status_service
  port_listening "${RZ_HARNESS_PROXY_PORT:-19080}" || \
    emit_failure CHECK_PROXY "proxy is not listening"
  port_listening "${RZ_FRONTEND_DEV_PORT:-9527}" || \
    emit_failure CHECK_FRONTEND "mapSystem is not listening"
  printf 'WEB_STACK=READY\n'
}

[[ -n "$action" ]] || emit_failure USAGE "missing action"
mkdir -p "$state_dir" || emit_failure PRECHECK "state directory cannot be created: $state_dir"

if [[ "$service" == "check-web-stack" ]]; then
  [[ "$action" == "--backend" && -n "${3:-}" ]] || \
    emit_failure CHECK_WEB_STACK "expected --backend <service>"
  service="$3"
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
