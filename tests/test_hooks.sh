#!/usr/bin/env bash
# Smoke tests for hook scripts.
#
# Hooks signal decisions via JSON on stdout: {"decision":"block",...} or {"decision":"warn",...}
# Exit code is always 0 (Claude Code reads the JSON, not the exit code).
#
# Usage: bash tests/test_hooks.sh

HOOKS_DIR="$(cd "$(dirname "$0")/../hooks" && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# Returns 0 if hook output contains a block or warn decision
hook_intercepts() {
  local script="$1"
  local input="$2"
  local output
  output=$(echo "$input" | bash "$HOOKS_DIR/$script" 2>/dev/null)
  echo "$output" | grep -qE '"decision":"(block|warn)"'
}

# Returns 0 if hook output has no decision (allows through)
hook_allows() {
  local script="$1"
  local input="$2"
  local output
  output=$(echo "$input" | bash "$HOOKS_DIR/$script" 2>/dev/null)
  ! echo "$output" | grep -qE '"decision":"(block|warn)"'
}

# ---- no-em-dashes.sh (PreToolUse, reads tool_input) ----
# Uses decision:block. Skips code file extensions.

EM_DASH=$'\xe2\x80\x94'
hook_intercepts "no-em-dashes.sh" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/tmp/test.md\",\"content\":\"This is great ${EM_DASH} really good.\"}}" \
  && pass "no-em-dashes: intercepts em dash in .md" \
  || fail "no-em-dashes: should have intercepted em dash"

hook_allows "no-em-dashes.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"This is great, really good."}}' \
  && pass "no-em-dashes: allows clean text" \
  || fail "no-em-dashes: falsely intercepted clean text"

hook_allows "no-em-dashes.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.sh","content":"# a shell comment"}}' \
  && pass "no-em-dashes: allows .sh files" \
  || fail "no-em-dashes: falsely intercepted code file"

# ---- no-ai-filler.sh (PostToolUse, reads tool_input, decision:warn) ----

hook_intercepts "no-ai-filler.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"In today'\''s fast-paced environment, leverage cutting-edge solutions."}}' \
  && pass "no-ai-filler: intercepts marketing filler" \
  || fail "no-ai-filler: should have intercepted filler"

hook_allows "no-ai-filler.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"Here is the updated implementation."}}' \
  && pass "no-ai-filler: allows normal content" \
  || fail "no-ai-filler: falsely intercepted normal content"

hook_intercepts "no-ai-filler.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"The mechanism is simple: poll, then ack."}}' \
  && pass "no-ai-filler: intercepts register tell in prose" \
  || fail "no-ai-filler: should have intercepted register tell"

hook_allows "no-ai-filler.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.py","content":"# The mechanism is X. By extension, Y.\ndef f(): pass"}}' \
  && pass "no-ai-filler: allows register phrase in code file" \
  || fail "no-ai-filler: should not flag register phrase in code"

hook_intercepts "no-ai-filler.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"The framework dominates current practice. Most teams skip step three.\n\nThe pattern shows up across portfolios. Roughly 60 percent.\n\nThe distinction matters at scale. Small books absorb noise."}}' \
  && pass "no-ai-filler: intercepts abstract-noun paragraph openers" \
  || fail "no-ai-filler: should have intercepted abstract openers"

# ---- protect-main.sh (PreToolUse Bash, reads tool_input.command, decision:block) ----

hook_intercepts "protect-main.sh" \
  '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' \
  && pass "protect-main: intercepts push to main" \
  || fail "protect-main: should have intercepted push to main"

hook_allows "protect-main.sh" \
  '{"tool_name":"Bash","tool_input":{"command":"git push origin feature/my-branch"}}' \
  && pass "protect-main: allows feature branch push" \
  || fail "protect-main: falsely intercepted feature branch"

# ---- no-placeholders.sh (PostToolUse, reads tool_input, decision:warn) ----

hook_intercepts "no-placeholders.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/config.json","content":"{\"key\": \"YOUR_VALUE_HERE\"}"}}' \
  && pass "no-placeholders: intercepts YOUR_VALUE_HERE" \
  || fail "no-placeholders: should have intercepted placeholder"

hook_allows "no-placeholders.sh" \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/config.json","content":"{\"key\": \"loaded-from-env\"}"}}' \
  && pass "no-placeholders: allows normal content" \
  || fail "no-placeholders: falsely intercepted normal content"

# ---- no-fake-urls.sh (PostToolUse, reads tool_result, decision:warn) ----
# Note: reads tool_result.content, not tool_input

hook_intercepts "no-fake-urls.sh" \
  '{"tool_name":"Write","tool_result":{"content":"Visit https://made-up-domain-xyz.io for details."}}' \
  && pass "no-fake-urls: intercepts unknown domain" \
  || fail "no-fake-urls: should have intercepted unknown domain"

hook_allows "no-fake-urls.sh" \
  '{"tool_name":"Write","tool_result":{"content":"Visit https://github.com for details."}}' \
  && pass "no-fake-urls: allows known domain" \
  || fail "no-fake-urls: falsely intercepted known domain"

# ---- Summary ----
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
