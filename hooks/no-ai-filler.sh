#!/bin/bash
# PostToolUse hook: Blocks generic AI filler phrases
# Matcher: Edit|Write|MultiEdit | Timeout: 5s

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOCKLIST="$SCRIPT_DIR/ai-filler-blocklist.txt"

if [ ! -f "$BLOCKLIST" ]; then
  exit 0
fi

INPUT=$(cat)
MATCH=$(echo "$INPUT" | python3 -c "
import sys, json, re
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
text = ti.get('new_string', '') or ti.get('content', '')
if not text and 'edits' in ti:
    text = ' '.join(e.get('new_string', '') for e in ti.get('edits', []))
text_lower = text.lower()
with open('$BLOCKLIST') as f:
    for line in f:
        phrase = line.strip().lower()
        if phrase and phrase in text_lower:
            print(line.strip())
            break
" 2>/dev/null)

if [ -n "$MATCH" ]; then
  echo "{\"decision\":\"warn\",\"reason\":\"AI filler phrase detected: '${MATCH}'. Rewrite with specific, concrete language.\"}"
  exit 0
fi

exit 0
