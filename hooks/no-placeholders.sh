#!/bin/bash
# PostToolUse hook: Blocks placeholder content in written files
# Matcher: Edit|Write|MultiEdit | Timeout: 5s

INPUT=$(cat)
MATCH=$(echo "$INPUT" | python3 -c "
import sys, json, re
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
text = ti.get('new_string', '') or ti.get('content', '')
if not text and 'edits' in ti:
    text = ' '.join(e.get('new_string', '') for e in ti.get('edits', []))
patterns = ['Lorem ipsum', 'PLACEHOLDER', 'example\\.com', 'your-.*-here', 'FIXME']
for p in patterns:
    m = re.search(p, text, re.IGNORECASE)
    if m:
        print(m.group())
        break
" 2>/dev/null)

if [ -n "$MATCH" ]; then
  echo "{\"decision\":\"warn\",\"reason\":\"Placeholder content detected: '${MATCH}'. Replace with real content.\"}"
  exit 0
fi

exit 0
