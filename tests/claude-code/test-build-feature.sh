#!/usr/bin/env bash
# Test: build-feature skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: build-feature skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the build-feature skill? Describe its key steps briefly." 30)

if assert_contains "$output" "build-feature\|Build Feature" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Load.*Spec\|read.*spec\|spec.json\|extract.*tasks" "Mentions loading spec"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify skill describes correct workflow order
echo "Test 2: Workflow ordering..."

output=$(run_claude "In the build-feature skill, what comes first: spec compliance review or code quality review? Be specific about the order." 30)

if assert_order "$output" "spec.*compliance" "code.*quality" "Spec compliance before code quality"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify simplification pass is mentioned
echo "Test 3: Simplification pass..."

output=$(run_claude "Does the build-feature skill run a simplification pass before review? What must it preserve?" 30)

if assert_contains "$output" "simplification\|simplifier" "Mentions simplification"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "behavior\|scope" "Preserves behavior or scope"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify Phase selection
echo "Test 4: Phase selection..."

output=$(run_claude "In build-feature, how does the orchestrator determine the current Phase to execute?" 30)

if assert_contains "$output" "spec.json\|manifest" "Uses manifest"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "first.*Phase\|status.*complete\|not.*complete" "Finds first incomplete Phase"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify spec compliance reviewer is skeptical
echo "Test 5: Spec compliance reviewer mindset..."

output=$(run_claude "What is the spec compliance reviewer's attitude toward coder reports in build-feature?" 30)

if assert_contains "$output" "not trust\|don't trust\|skeptical\|verify.*independently\|suspiciously" "Reviewer is skeptical"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "read.*code\|inspect.*code\|verify.*code" "Reviewer reads code"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify review loops
echo "Test 6: Review loop requirements..."

output=$(run_claude "In build-feature, what happens if a reviewer finds issues? Is it a one-time review or a loop?" 30)

if assert_contains "$output" "loop\|again\|repeat\|until.*approved\|until.*compliant" "Review loops mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "fix.*agent\|agent.*fix\|fix.*issues" "Fix agents handle issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify full task text is provided
echo "Test 7: Task context provision..."

output=$(run_claude "In build-feature, how does the orchestrator provide task information to the coder agent? Does it make the agent discover the task alone or provide the needed context directly?" 30)

if assert_contains "$output" "provide.*directly\|full.*text\|paste\|include.*prompt" "Provides text directly"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "requirements\|design\|task.*content\|manifest" "Includes required context"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify prerequisites
echo "Test 8: Prerequisites..."

output=$(run_claude "What files must exist before using build-feature?" 30)

if assert_contains "$output" "docs/specs\|spec.json" "Mentions spec folder or manifest"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify no-subagent fallback
echo "Test 9: No-subagent fallback..."

output=$(run_claude "What should build-feature do if no subagent tool is available?" 30)

if assert_contains "$output" "report.*limitation\|ask\|sequential" "Reports limitation and asks before sequential execution"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All build-feature skill tests passed ==="
