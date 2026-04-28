#!/bin/bash
# PreToolUse hook: Blocks em dashes, en dashes, and double-hyphen substitutes in content/UI files
# Matcher: Edit|Write|MultiEdit | Timeout: 5s
# Excludes code files where these may appear legitimately

INPUT=$(cat)

# Extract file path, content, and determine if content/UI file
RESULT=$(echo "$INPUT" | python3 -c "
import sys, json, os, re
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
fp = ti.get('file_path', '')
text = ti.get('new_string', '') or ti.get('content', '')
if not text and 'edits' in ti:
    text = ' '.join(e.get('new_string', '') for e in ti.get('edits', []))
ext = os.path.splitext(fp)[1].lower() if fp else ''

# Code files: skip entirely (em dashes and double hyphens are fine in code)
code_exts = {'.ts', '.tsx', '.js', '.jsx', '.py', '.rb', '.go', '.rs', '.java', '.swift',
             '.json', '.yaml', '.yml', '.toml', '.css', '.scss', '.less',
             '.sh', '.bash', '.zsh', '.sql', '.graphql', '.c', '.cpp', '.h', '.cs',
             '.env', '.conf', '.ini', '.cfg', '.lock'}
if ext in code_exts:
    print('SKIP')
    sys.exit()

# Content/UI files: check for em dashes AND double-hyphen substitutes
# For HTML files, only check text content (not inside HTML tags, attributes, or comments)
if ext in {'.html', '.htm', '.svelte', '.vue'}:
    # Strip HTML tags, comments, style blocks, script blocks to check only visible text
    cleaned = re.sub(r'<style[^>]*>.*?</style>', '', text, flags=re.DOTALL)
    cleaned = re.sub(r'<script[^>]*>.*?</script>', '', cleaned, flags=re.DOTALL)
    cleaned = re.sub(r'<!--.*?-->', '', cleaned, flags=re.DOTALL)
    cleaned = re.sub(r'<[^>]+>', '', cleaned)
    print(cleaned)
else:
    print(text)
" 2>/dev/null)

# If code file, allow through
if [ "$RESULT" = "SKIP" ]; then
  exit 0
fi

CONTENT="$RESULT"

# Check for em dash (U+2014) or en dash (U+2013)
if echo "$CONTENT" | grep -q $'\xe2\x80\x94\|\xe2\x80\x93'; then
  echo '{"decision":"block","reason":"Content contains em dash or en dash. Rewrite the sentence to avoid them entirely."}'
  exit 0
fi

# Double-hyphen check removed (was blocking dispatches/CLI content).
# Rule now lives in CLAUDE.md instead of hook enforcement.

exit 0
