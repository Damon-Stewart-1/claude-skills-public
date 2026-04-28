#!/bin/bash
# PostToolUse hook: Flags URLs not from known domains
# Matcher: Edit|Write|MultiEdit | Timeout: 5s

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | python3 -c "
import sys, json, re
data = json.load(sys.stdin)
result = data.get('tool_result', {})
text = ''
if isinstance(result, dict):
    text = result.get('content', '') or result.get('new_string', '')
    if isinstance(text, list):
        text = ' '.join(str(t) for t in text)
urls = re.findall(r'https?://[^\s\"<>)\]]+', str(text))
known = ['vercel.app','github.com','google.com','googleapis.com','anthropic.com',
         'npmjs.com','earnedimpact.org','earnedimpactadvisory.com','figma.com',
         'productive.io','calendly.com','linkedin.com','youtube.com']
suspect = [u for u in urls if not any(d in u for d in known)]
if suspect:
    print('\n'.join(suspect[:5]))
" 2>/dev/null)

if [ -n "$CONTENT" ]; then
  echo "{\"decision\":\"warn\",\"reason\":\"Possible hallucinated URLs detected -- verify these exist:\\n${CONTENT}\"}"
  exit 0
fi

exit 0
