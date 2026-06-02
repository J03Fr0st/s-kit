#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "test-codex-hooks: $*" >&2
  exit 1
}

[ -f ".codex-plugin/plugin.json" ] || fail "missing .codex-plugin/plugin.json"
[ -f "hooks/hooks.json" ] || fail "missing hooks/hooks.json"
[ -f "hooks/session-start" ] || fail "missing hooks/session-start"
[ -f "hooks/run-hook.cmd" ] || fail "missing hooks/run-hook.cmd"

[ ! -e "hooks/hooks-codex.json" ] || fail "unexpected unsupported hooks/hooks-codex.json"
[ ! -e "hooks/session-start-codex" ] || fail "unexpected unsupported hooks/session-start-codex"

node <<'NODE'
const fs = require('fs');

function fail(message) {
  console.error(`test-codex-hooks: ${message}`);
  process.exit(1);
}

const plugin = JSON.parse(fs.readFileSync('.codex-plugin/plugin.json', 'utf8'));
if (plugin.hooks !== './hooks/hooks.json') {
  fail('.codex-plugin/plugin.json must declare hooks as ./hooks/hooks.json');
}

const hookConfig = JSON.parse(fs.readFileSync('hooks/hooks.json', 'utf8'));
const sessionStart = hookConfig.hooks?.SessionStart;
if (!Array.isArray(sessionStart) || sessionStart.length === 0) {
  fail('hooks/hooks.json must define a SessionStart hook');
}

const expectedMatchers = ['startup', 'resume', 'clear', 'compact'];
const actualMatchers = sessionStart.map((group) => group.matcher);
if (JSON.stringify(actualMatchers) !== JSON.stringify(expectedMatchers)) {
  fail(`SessionStart must expose one hook group per start source: ${expectedMatchers.join(', ')}`);
}

for (const group of sessionStart) {
  const commandHooks = (group.hooks ?? []).filter((hook) => hook.type === 'command');
  if (commandHooks.length !== 1) {
    fail(`SessionStart ${group.matcher} must define exactly one command hook`);
  }

  const command = commandHooks[0].command;
  if (!command || !command.includes('run-hook.cmd') || !command.includes('session-start')) {
    fail(`SessionStart ${group.matcher} must call hooks/run-hook.cmd session-start`);
  }
  if (!command.includes('${PLUGIN_ROOT}/hooks/run-hook.cmd')) {
    fail(`SessionStart ${group.matcher} must use ${PLUGIN_ROOT}/hooks/run-hook.cmd`);
  }
  if (command.includes('${CLAUDE_PLUGIN_ROOT}')) {
    fail(`SessionStart ${group.matcher} must not use ${CLAUDE_PLUGIN_ROOT}`);
  }
}
NODE

session_output="$(PLUGIN_ROOT="$ROOT" bash hooks/run-hook.cmd session-start)"
SESSION_OUTPUT="$session_output" node <<'NODE'
const payload = JSON.parse(process.env.SESSION_OUTPUT);
if (!payload.additionalContext || !payload.additionalContext.includes('You have s-kit.')) {
  console.error('test-codex-hooks: declared hook command must emit SDK-standard additionalContext');
  process.exit(1);
}
NODE

echo "Codex plugin hook packaging verified."
