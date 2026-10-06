#!/usr/bin/env bash
set -eu

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
cleanup() {
  local pid_file pid
  for pid_file in "$tmp_dir"/ready-state/backend-sales-management.pid; do
    [[ -f "$pid_file" ]] || continue
    pid="$(<"$pid_file")"
    kill "$pid" 2>/dev/null || true
  done
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

run_expect_fail() {
  local label="$1" expected="$2"
  shift 2
  if "$@" >"$tmp_dir/output" 2>&1; then
    printf 'FAIL: %s unexpectedly passed\n' "$label" >&2
    return 1
  fi
  grep -q "$expected" "$tmp_dir/output"
  grep -q '^PHASE=' "$tmp_dir/output"
  grep -q '^SERVICE=' "$tmp_dir/output"
  grep -q '^LOG=' "$tmp_dir/output"
  grep -q '^MESSAGE=' "$tmp_dir/output"
}

run_expect_pass() {
  local label="$1"
  shift
  "$@" >"$tmp_dir/output" 2>&1 || {
    cat "$tmp_dir/output" >&2
    return 1
  }
  printf 'PASS: %s\n' "$label"
}

mkdir -p "$tmp_dir/bin"
cat >"$tmp_dir/bin/mvn-success" <<'EOF'
#!/usr/bin/env bash
mkdir -p "$(dirname "$SFA_TEST_JAR")"
: >"$SFA_TEST_JAR"
exit 0
EOF
cat >"$tmp_dir/bin/mvn-fail" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$tmp_dir/bin/java-health-up" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  exit 0
fi
trap 'exit 0' TERM INT
while :; do
  sleep 1
done
EOF
cat >"$tmp_dir/bin/java-health-down" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp_dir/bin/kill-dead" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-0" ]]; then
  exit 1
fi
exit 0
EOF
cat >"$tmp_dir/bin/curl-health-up" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '{"status":"UP"}'
EOF
cat >"$tmp_dir/bin/curl-health-down" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '{"status":"DOWN"}'
EOF
cat >"$tmp_dir/bin/lsof-listening" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"-iTCP:${SFA_TEST_LISTENING_PORTS%%,*}"*) exit 0 ;;
esac
for port in ${SFA_TEST_LISTENING_PORTS//,/ }; do
  case "$*" in
    *"-iTCP:$port"*) exit 0 ;;
  esac
done
exit 1
EOF
cat >"$tmp_dir/bin/ps-unrelated" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'java -jar /tmp/unrelated-service.jar'
EOF
cat >"$tmp_dir/bin/ps-target" <<'EOF'
#!/usr/bin/env bash
printf 'java -jar %s\n' "$SFA_TEST_JAR"
EOF
cat >"$tmp_dir/bin/kill-record" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SFA_TEST_KILL_LOG"
EOF
cat >"$tmp_dir/bin/sleep-success" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp_dir/bin/stat-fixed" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '1720000000'
EOF
cat >"$tmp_dir/bin/date-fixed" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '2026-07-13T10:30:00+0800'
EOF
chmod +x "$tmp_dir/bin/"*

jar="$tmp_dir/repo/sfa-sales-management-interfaces/target/sfa-sales-management-interfaces-1.0-SNAPSHOT.jar"
mkdir -p "$tmp_dir/repo"

run_expect_fail "unsupported service fails closed" "unsupported service" \
  "$root/scripts/local-service-lifecycle.sh" other-service status
run_expect_fail "status reports missing PID" "PHASE=CHECK_PROCESS" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/state" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management status
run_expect_fail "restart rejects down health" "PHASE=WAIT_HEALTH" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/state" \
  SFA_TEST_JAR="$jar" \
  SFA_LIFECYCLE_MAVEN_BIN="$tmp_dir/bin/mvn-success" \
  SFA_LIFECYCLE_JAVA_BIN="$tmp_dir/bin/java-health-down" \
  SFA_LIFECYCLE_CURL_BIN="$tmp_dir/bin/curl-health-down" \
  SFA_LIFECYCLE_LSOF_BIN="$tmp_dir/bin/lsof-listening" \
  SFA_TEST_LISTENING_PORTS=31010 \
  SFA_LIFECYCLE_SLEEP_BIN="$tmp_dir/bin/sleep-success" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management restart

run_expect_fail "restart rejects exited process after listener and health" "PHASE=CHECK_PROCESS" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/exited-after-health-state" \
  SFA_TEST_JAR="$jar" \
  SFA_LIFECYCLE_MAVEN_BIN="$tmp_dir/bin/mvn-success" \
  SFA_LIFECYCLE_JAVA_BIN="$tmp_dir/bin/java-health-down" \
  SFA_LIFECYCLE_CURL_BIN="$tmp_dir/bin/curl-health-up" \
  SFA_LIFECYCLE_LSOF_BIN="$tmp_dir/bin/lsof-listening" \
  SFA_LIFECYCLE_KILL_BIN="$tmp_dir/bin/kill-dead" \
  SFA_TEST_LISTENING_PORTS=31010 \
  SFA_LIFECYCLE_SLEEP_BIN="$tmp_dir/bin/sleep-success" \
  SFA_LIFECYCLE_STAT_BIN="$tmp_dir/bin/stat-fixed" \
  SFA_LIFECYCLE_DATE_BIN="$tmp_dir/bin/date-fixed" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management restart
! grep -q '^PHASE=READY$' "$tmp_dir/output"

mkdir -p "$tmp_dir/unrelated-state"
printf '%s\n' '4242' >"$tmp_dir/unrelated-state/backend-sales-management.pid"
run_expect_fail "stop refuses unrelated PID" "PHASE=STOP_OLD" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/unrelated-state" \
  SFA_LIFECYCLE_PS_BIN="$tmp_dir/bin/ps-unrelated" \
  SFA_LIFECYCLE_KILL_BIN="$tmp_dir/bin/kill-record" \
  SFA_TEST_KILL_LOG="$tmp_dir/unrelated-kill.log" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management stop
[[ ! -s "$tmp_dir/unrelated-kill.log" ]] || {
  printf 'FAIL: unrelated PID received a signal\n' >&2
  exit 1
}

mkdir -p "$tmp_dir/build-fail-state"
printf '%s\n' '4242' >"$tmp_dir/build-fail-state/backend-sales-management.pid"
run_expect_fail "failed build preserves existing process" "PHASE=PACKAGE" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/build-fail-state" \
  SFA_TEST_JAR="$jar" \
  SFA_TEST_KILL_LOG="$tmp_dir/build-fail-kill.log" \
  SFA_LIFECYCLE_MAVEN_BIN="$tmp_dir/bin/mvn-fail" \
  SFA_LIFECYCLE_PS_BIN="$tmp_dir/bin/ps-target" \
  SFA_LIFECYCLE_KILL_BIN="$tmp_dir/bin/kill-record" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management restart
[[ ! -s "$tmp_dir/build-fail-kill.log" ]] || {
  printf 'FAIL: failed build signaled an existing process\n' >&2
  exit 1
}

run_expect_pass "restart reports verified ready state" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/ready-state" \
  SFA_TEST_JAR="$jar" \
  SFA_LIFECYCLE_MAVEN_BIN="$tmp_dir/bin/mvn-success" \
  SFA_LIFECYCLE_JAVA_BIN="$tmp_dir/bin/java-health-up" \
  SFA_LIFECYCLE_CURL_BIN="$tmp_dir/bin/curl-health-up" \
  SFA_LIFECYCLE_LSOF_BIN="$tmp_dir/bin/lsof-listening" \
  SFA_TEST_LISTENING_PORTS=31010 \
  SFA_LIFECYCLE_SLEEP_BIN="$tmp_dir/bin/sleep-success" \
  SFA_LIFECYCLE_STAT_BIN="$tmp_dir/bin/stat-fixed" \
  SFA_LIFECYCLE_DATE_BIN="$tmp_dir/bin/date-fixed" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management restart
grep -q '^SERVICE=backend-sales-management$' "$tmp_dir/output"
grep -q '^HEALTH=UP$' "$tmp_dir/output"
grep -q '^PID=[0-9][0-9]*$' "$tmp_dir/output"
grep -q '^PORT=31010$' "$tmp_dir/output"
grep -q '^JAR_MTIME=1720000000$' "$tmp_dir/output"
grep -q '^STARTED_AT=2026-07-13T10:30:00+0800$' "$tmp_dir/output"
grep -q '^LOG=' "$tmp_dir/output"

run_expect_pass "stop removes target owned PID" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/ready-state" \
  SFA_TEST_JAR="$jar" \
  SFA_LIFECYCLE_PS_BIN="$tmp_dir/bin/ps-target" \
  "$root/scripts/local-service-lifecycle.sh" backend-sales-management stop
[[ ! -f "$tmp_dir/ready-state/backend-sales-management.pid" ]] || {
  printf 'FAIL: target PID file was not removed\n' >&2
  exit 1
}

mkdir -p "$tmp_dir/web-stack-state"
printf '%s\n' '4242' >"$tmp_dir/web-stack-state/backend-sales-management.pid"
run_expect_fail "check-web-stack reports frontend layer failure" "PHASE=CHECK_FRONTEND" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/web-stack-state" \
  SFA_TEST_JAR="$jar" \
  SFA_TEST_LISTENING_PORTS=31010,19080 \
  SFA_LIFECYCLE_PS_BIN="$tmp_dir/bin/ps-target" \
  SFA_LIFECYCLE_LSOF_BIN="$tmp_dir/bin/lsof-listening" \
  "$root/scripts/local-service-lifecycle.sh" check-web-stack --backend backend-sales-management

run_expect_pass "check-web-stack reports all layers ready" \
  env SFA_REPO_BACKEND_SALES_MANAGEMENT="$tmp_dir/repo" \
  SFA_LIFECYCLE_STATE_DIR="$tmp_dir/web-stack-state" \
  SFA_TEST_JAR="$jar" \
  SFA_TEST_LISTENING_PORTS=31010,19080,9527 \
  SFA_LIFECYCLE_PS_BIN="$tmp_dir/bin/ps-target" \
  SFA_LIFECYCLE_LSOF_BIN="$tmp_dir/bin/lsof-listening" \
  "$root/scripts/local-service-lifecycle.sh" check-web-stack --backend backend-sales-management
grep -q '^WEB_STACK=READY$' "$tmp_dir/output"
