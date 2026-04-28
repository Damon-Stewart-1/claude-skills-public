#!/bin/bash
# PostToolUse hook: Enforces completion promises in plan files
# Matcher: Write | Timeout: 5s

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only check files written to ~/.claude/plans/
if ! echo "$FILE_PATH" | grep -q '\.claude/plans/'; then
  exit 0
fi

# Skip archive directory
if echo "$FILE_PATH" | grep -q 'plans/archive/'; then
  exit 0
fi

# Check for completion promises
PHASES=$(echo "$INPUT" | python3 -c "
import sys, json, re
data = json.load(sys.stdin)
content = data.get('tool_input', {}).get('content', '')
phases = re.findall(r'## Phase \d', content)
promises = re.findall(r'[Cc]ompletion promise', content)
if phases and not promises:
    print(f'{len(phases)} phases found but no completion promises')
" 2>/dev/null)

if [ -n "$PHASES" ]; then
  echo "{\"decision\":\"warn\",\"reason\":\"Plan quality: ${PHASES}. Every phase should have a 'Completion promise:' with a verifiable bash check.\"}"
  exit 0
fi

exit 0
