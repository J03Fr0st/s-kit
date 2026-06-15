#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SKIT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
START_SCRIPT="$REPO_ROOT/skills/brainstorming/scripts/start-server.sh"

TEST_DIR="${TMPDIR:-/tmp}/brainstorm-start-test-$$"
passed=0
failed=0

cleanup() {
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

assert_match() {
  local name="$1"
  local value="$2"
  local pattern="$3"
  if [[ "$value" =~ $pattern ]]; then
    pass "$name"
  else
    fail "$name" "Value '$value' did not match $pattern"
  fi
}

mkdir -p "$TEST_DIR/fake-bin"

cat > "$TEST_DIR/fake-bin/node" <<'FAKENODE'
#!/usr/bin/env bash
{
  printf 'BRAINSTORM_DIR=%s\n' "${BRAINSTORM_DIR:-}"
  printf 'BRAINSTORM_HOST=%s\n' "${BRAINSTORM_HOST:-}"
  printf 'BRAINSTORM_URL_HOST=%s\n' "${BRAINSTORM_URL_HOST:-}"
  printf 'BRAINSTORM_OWNER_PID=%s\n' "${BRAINSTORM_OWNER_PID-__UNSET__}"
  printf 'BRAINSTORM_PORT_FILE=%s\n' "${BRAINSTORM_PORT_FILE:-}"
  printf 'BRAINSTORM_TOKEN_FILE=%s\n' "${BRAINSTORM_TOKEN_FILE:-}"
  printf 'BRAINSTORM_IDLE_TIMEOUT_MS=%s\n' "${BRAINSTORM_IDLE_TIMEOUT_MS:-}"
  printf 'BRAINSTORM_OPEN=%s\n' "${BRAINSTORM_OPEN:-}"
  printf 'ARGV=%s\n' "$*"
} > "$CAPTURE_FILE"
echo '{"event":"server-started","url":"http://localhost:49152/?key=test","port":49152}'
FAKENODE
chmod +x "$TEST_DIR/fake-bin/node"

cat > "$TEST_DIR/fake-bin/uname" <<'FAKEUNAME'
#!/usr/bin/env bash
echo "MINGW64_NT-test"
FAKEUNAME
chmod +x "$TEST_DIR/fake-bin/uname"

PROJECT_DIR="$TEST_DIR/project"
CAPTURE_FILE="$TEST_DIR/capture.env"

echo ""
echo "=== start-server.sh tests ==="

output=$(
  CAPTURE_FILE="$CAPTURE_FILE" \
  PATH="$TEST_DIR/fake-bin:$PATH" \
  "$START_SCRIPT" --project-dir "$PROJECT_DIR" --idle-timeout-minutes 5 --open 2>&1
)
status=$?

if [[ $status -eq 0 ]]; then
  pass "Windows-like uname auto-foregrounds and starts through fake node"
else
  fail "Windows-like uname auto-foregrounds and starts through fake node" "Exit $status, output: $output"
fi

if [[ -f "$CAPTURE_FILE" ]]; then
  pass "fake node captured environment"
else
  fail "fake node captured environment" "Capture file was not written; output: $output"
fi

owner_pid="$(grep '^BRAINSTORM_OWNER_PID=' "$CAPTURE_FILE" 2>/dev/null | sed 's/^BRAINSTORM_OWNER_PID=//')"
assert_eq "Windows-like shells clear BRAINSTORM_OWNER_PID" "" "$owner_pid"

argv="$(grep '^ARGV=' "$CAPTURE_FILE" 2>/dev/null | sed 's/^ARGV=//')"
id_count="$(printf '%s\n' "$argv" | grep -o -- '--brainstorm-server-id=[A-Za-z0-9_-]*' | wc -l | tr -d ' ')"
assert_eq "node argv includes exactly one server instance id" "1" "$id_count"

server_id="$(printf '%s\n' "$argv" | grep -o -- '--brainstorm-server-id=[A-Za-z0-9_-]*' | sed 's/^--brainstorm-server-id=//')"
assert_match "server instance id is shell-safe" "$server_id" '^[A-Za-z0-9_-]{32,64}$'

mapfile -t id_files < <(find "$PROJECT_DIR/.s-kit/brainstorm" -path '*/state/server-instance-id' -type f 2>/dev/null)
assert_eq "server-instance-id is written under .s-kit state" "1" "${#id_files[@]}"
if [[ ${#id_files[@]} -eq 1 ]]; then
  persisted_id="$(cat "${id_files[0]}")"
  assert_eq "persisted server id matches argv" "$server_id" "$persisted_id"
  state_dir="$(dirname "${id_files[0]}")"
else
  state_dir=""
fi

if find "$PROJECT_DIR" -path '*.superpowers*' | grep -q .; then
  fail "start-server.sh does not create .superpowers paths" "Found .superpowers path under $PROJECT_DIR"
else
  pass "start-server.sh does not create .superpowers paths"
fi

port_file="$(grep '^BRAINSTORM_PORT_FILE=' "$CAPTURE_FILE" | sed 's/^BRAINSTORM_PORT_FILE=//')"
token_file="$(grep '^BRAINSTORM_TOKEN_FILE=' "$CAPTURE_FILE" | sed 's/^BRAINSTORM_TOKEN_FILE=//')"
assert_eq "BRAINSTORM_PORT_FILE points at state/.last-port" "$state_dir/.last-port" "$port_file"
assert_eq "BRAINSTORM_TOKEN_FILE points at state/.last-token" "$state_dir/.last-token" "$token_file"

idle_ms="$(grep '^BRAINSTORM_IDLE_TIMEOUT_MS=' "$CAPTURE_FILE" | sed 's/^BRAINSTORM_IDLE_TIMEOUT_MS=//')"
open_flag="$(grep '^BRAINSTORM_OPEN=' "$CAPTURE_FILE" | sed 's/^BRAINSTORM_OPEN=//')"
assert_eq "--idle-timeout-minutes is converted to milliseconds" "300000" "$idle_ms"
assert_eq "--open passes BRAINSTORM_OPEN=1" "1" "$open_flag"

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [[ $failed -gt 0 ]]; then
  exit 1
fi
exit 0
