#!/bin/bash
# PostToolUse hook: Blocks hardcoded secrets in non-.env files
# Matcher: Edit|Write|MultiEdit | Timeout: 5s
#
# Only handles non-.env files (BLOCK).
# The .env warn is in secrets-env-gate.sh (PreToolUse) so it gates BEFORE the write.

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

# Skip .env files - handled by PreToolUse gate
if echo "$FILE_PATH" | grep -qE '\.env(\..*)?$'; then
  exit 0
fi

SECRET_MATCH=$(echo "$CONTENT" | grep -oE '(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]{20,}|re_[a-zA-Z0-9]{20,}|xoxb-[0-9]{10,}|ghp_[a-zA-Z0-9]{30,}|gho_[a-zA-Z0-9]{30,}|AIza[a-zA-Z0-9_-]{30,}|ya29\.[a-zA-Z0-9_-]{20,}|whsec_[a-zA-Z0-9]{20,}|sk_test_[a-zA-Z0-9]{20,})' | head -1)

if [ -z "$SECRET_MATCH" ]; then
  exit 0
fi

SECRET_PREFIX="${SECRET_MATCH:0:8}..."
echo "{\"decision\":\"block\",\"reason\":\"Blocked: hardcoded secret (${SECRET_PREFIX}) detected in ${FILE_PATH}. Use an env var reference instead. Secrets belong in .env files or Vercel env vars.\"}"
exit 0
