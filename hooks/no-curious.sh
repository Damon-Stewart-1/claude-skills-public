#!/bin/bash
# PreToolUse hook: Blocks writes that start with "Curious" or "Curiously"
# Matcher: Edit|Write|MultiEdit | Timeout: 5s

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
# Check new_string (Edit), content (Write), or edits array (MultiEdit)
text = ti.get('new_string', '') or ti.get('content', '')
if not text and 'edits' in ti:
    text = ' '.join(e.get('new_string', '') for e in ti.get('edits', []))
print(text[:50])
" 2>/dev/null)

if echo "$CONTENT" | grep -qiE '^Curious(ly)?[[:space:],]'; then
  echo '{"decision":"block","reason":"Content starts with \"Curious\" -- rephrase the opening."}'
  exit 0
fi

exit 0
