#!/bin/bash
# PreToolUse hook: Gates secret writes to .env files BEFORE they happen
# Matcher: Edit|Write|MultiEdit | Timeout: 5s
#
# Blocks the write so Claude must ask user: disk or 1Password?
# Only fires for .env files. Non-.env blocking is in secrets-write-guard.sh (PostToolUse).

INPUT=$(cat)

eval "$(echo "$INPUT" | python3 -c "
import sys, json, shlex
data = json.load(sys.stdin)
ti = data.get('tool_input', {})
fp = ti.get('file_path', '') or ti.get('filePath', '')
content = ti.get('new_string', '') or ti.get('content', '')
if not content and 'edits' in ti:
    content = ' '.join(e.get('new_string', '') for e in ti.get('edits', []))
print(f'FILE_PATH={shlex.quote(fp)}')
print(f'CONTENT={shlex.quote(content)}')
" 2>/dev/null)"

if [ -z "$FILE_PATH" ] || [ -z "$CONTENT" ]; then
  exit 0
fi

# Only gate .env files
if ! echo "$FILE_PATH" | grep -qE '\.env(\..*)?$'; then
  exit 0
fi

SECRET_MATCH=$(echo "$CONTENT" | grep -oE '(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]{20,}|re_[a-zA-Z0-9]{20,}|xoxb-[0-9]{10,}|ghp_[a-zA-Z0-9]{30,}|gho_[a-zA-Z0-9]{30,}|AIza[a-zA-Z0-9_-]{30,}|ya29\.[a-zA-Z0-9_-]{20,}|whsec_[a-zA-Z0-9]{20,}|sk_test_[a-zA-Z0-9]{20,})' | head -1)

if [ -z "$SECRET_MATCH" ]; then
  exit 0
fi

SECRET_PREFIX="${SECRET_MATCH:0:8}..."
echo "{\"decision\":\"block\",\"reason\":\"Secret detected (${SECRET_PREFIX}) being written to ${FILE_PATH}. Ask user: should this live on disk in .env, or in 1Password only? If 1Password, use placeholder 'see-1password' instead.\"}"
exit 0
