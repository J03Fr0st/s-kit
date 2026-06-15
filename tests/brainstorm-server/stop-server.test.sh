#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SKIT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
STOP_SCRIPT="$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh"
SERVER_CJS="$REPO_ROOT/skills/brainstorming/scripts/server.cjs"

TEST_DIR="${TMPDIR:-/tmp}/brainstorm-stop-test-$$"
passed=0
failed=0
pids=()

cleanup() {
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

pass() {
  echo "  PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "  FAIL: $1"
  echo "    $2"
  failed=$((failed + 1))
}

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$name"
  else
    fail "$name" "Expected '$expected', got '$actual'"
  fi
}

assert_alive() {
  local name="$1"
  local pid="$2"
  if kill -0 "$pid" 2>/dev/null; then
    pass "$name"
  else
    fail "$name" "PID $pid is not alive"
  fi
}

assert_dead() {
  local name="$1"
  local pid="$2"
  if kill -0 "$pid" 2>/dev/null; then
    fail "$name" "PID $pid is still alive"
  else
    pass "$name"
  fi
}

status_of() {
  sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$1"
}

reason_file() {
  sed -n 's/.*"reason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1"
}

make_session() {
  local name="$1"
  local dir="$TEST_DIR/$name"
  mkdir -p "$dir/content" "$dir/state"
  printf '%s\n' "$dir"
}

write_state() {
  local dir="$1"
  local pid="$2"
  local server_id="$3"
  printf '%s\n' "$pid" > "$dir/state/server.pid"
  printf '%s\n' "$server_id" > "$dir/state/server-instance-id"
  printf '{"event":"server-started"}\n' > "$dir/state/server-info"
}

wait_for_info() {
  local dir="$1"
  for _ in $(seq 1 50); do
    if [[ -f "$dir/state/server-info" ]]; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

start_impostor() {
  local script="$1"
  shift
  node "$script" "$@" &
  STARTED_PID=$!
  pids+=("$STARTED_PID")
  sleep 0.2
}

mkdir -p "$TEST_DIR"
IMPOSTOR="$TEST_DIR/server.cjs"
cat > "$IMPOSTOR" <<'IMPOSTORJS'
setInterval(() => {}, 1000);
IMPOSTORJS

echo ""
echo "=== stop-server.sh tests ==="

valid_id="abcdefghijklmnopqrstuvwxyzABCDEF"

sleep 30 &
sleep_pid=$!
pids+=("$sleep_pid")
sleep_dir="$(make_session stale-sleep)"
write_state "$sleep_dir" "$sleep_pid" "$valid_id"
out="$(bash "$STOP_SCRIPT" "$sleep_dir")"
assert_eq "unrelated PID reports stale_pid" "stale_pid" "$(status_of "$out")"
assert_alive "unrelated PID is not killed" "$sleep_pid"
assert_eq "stale PID removes pid file" "missing" "$([[ -f "$sleep_dir/state/server.pid" ]] && echo present || echo missing)"
assert_eq "stale PID clears server-info" "missing" "$([[ -f "$sleep_dir/state/server-info" ]] && echo present || echo missing)"
assert_eq "stale PID writes stopped reason" "stale_pid" "$(reason_file "$sleep_dir/state/server-stopped")"

missing_dir="$(make_session missing-pid)"
out="$(bash "$STOP_SCRIPT" "$missing_dir")"
assert_eq "missing pid file reports not_running" "not_running" "$(status_of "$out")"

missing_id_dir="$(make_session missing-id)"
start_impostor "$IMPOSTOR"
missing_id_pid="$STARTED_PID"
printf '%s\n' "$missing_id_pid" > "$missing_id_dir/state/server.pid"
out="$(bash "$STOP_SCRIPT" "$missing_id_dir")"
assert_eq "server.cjs impostor with missing id reports stale_pid" "stale_pid" "$(status_of "$out")"
assert_alive "server.cjs impostor with missing id is not killed" "$missing_id_pid"

wrong_id_dir="$(make_session wrong-id)"
start_impostor "$IMPOSTOR" "--brainstorm-server-id=wrongwrongwrongwrongwrongwrongwrong1"
wrong_id_pid="$STARTED_PID"
write_state "$wrong_id_dir" "$wrong_id_pid" "$valid_id"
out="$(bash "$STOP_SCRIPT" "$wrong_id_dir")"
assert_eq "server.cjs impostor with wrong id reports stale_pid" "stale_pid" "$(status_of "$out")"
assert_alive "server.cjs impostor with wrong id is not killed" "$wrong_id_pid"

bad_id_dir="$(make_session malformed-id)"
start_impostor "$IMPOSTOR" "--brainstorm-server-id=$valid_id"
bad_id_pid="$STARTED_PID"
write_state "$bad_id_dir" "$bad_id_pid" "bad id!"
out="$(bash "$STOP_SCRIPT" "$bad_id_dir")"
assert_eq "malformed instance id fails closed as stale_pid" "stale_pid" "$(status_of "$out")"
assert_alive "malformed instance id does not signal process" "$bad_id_pid"

real_dir="$TEST_DIR/project/.s-kit/brainstorm/real-server"
mkdir -p "$real_dir/content" "$real_dir/state"
real_id="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef012345"
BRAINSTORM_DIR="$real_dir" \
BRAINSTORM_HOST="127.0.0.1" \
BRAINSTORM_URL_HOST="localhost" \
BRAINSTORM_OWNER_PID="" \
BRAINSTORM_IDLE_TIMEOUT_MS="60000" \
  node "$SERVER_CJS" "--brainstorm-server-id=$real_id" > "$real_dir/state/server.log" 2>&1 &
real_pid=$!
pids+=("$real_pid")
printf '%s\n' "$real_pid" > "$real_dir/state/server.pid"
printf '%s\n' "$real_id" > "$real_dir/state/server-instance-id"

if wait_for_info "$real_dir"; then
  pass "real brainstorm server starts"
else
  fail "real brainstorm server starts" "Log tail: $(tail -5 "$real_dir/state/server.log" 2>/dev/null)"
fi

out="$(bash "$STOP_SCRIPT" "$real_dir")"
assert_eq "real matching server reports stopped" "stopped" "$(status_of "$out")"
sleep 0.5
assert_dead "real matching server is stopped" "$real_pid"
assert_eq "persistent session directory is preserved" "present" "$([[ -d "$real_dir" ]] && echo present || echo missing)"
assert_eq "stopped server clears server-info" "missing" "$([[ -f "$real_dir/state/server-info" ]] && echo present || echo missing)"
assert_eq "stopped server clears instance id" "missing" "$([[ -f "$real_dir/state/server-instance-id" ]] && echo present || echo missing)"
assert_eq "stopped server writes stop reason" "stop-server.sh" "$(reason_file "$real_dir/state/server-stopped")"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [[ $failed -gt 0 ]]; then
  exit 1
fi
exit 0
