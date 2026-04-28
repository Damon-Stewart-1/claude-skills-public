#!/bin/bash
# PreToolUse hook: Blocks git push to main/master
# Matcher: Bash | Timeout: 5s

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if echo "$COMMAND" | grep -qE 'git push.*(main|master)'; then
  echo '{"decision":"block","reason":"Blocked: pushing directly to main/master. Use a feature branch and PR instead."}'
  exit 0
fi

exit 0
