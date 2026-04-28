#!/bin/bash
# PreToolUse hook: Blocks commands that expose or transmit secrets
# Matcher: Bash | Timeout: 5s
#
# ALLOWS: Reading .env files via the Read tool (not handled here)
# BLOCKS: Bash commands that dump, echo, print, or transmit secret values

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# For git checks, extract only lines that are actual git commands.
# Strategy: find lines starting with optional whitespace + "git add",
# but exclude lines that appear after a heredoc open (<<) on a prior line.
# We do this by extracting the command up to the first heredoc marker,
# then checking only those lines for git add violations.
BEFORE_HEREDOC=$(echo "$COMMAND" | python3 -c "
import sys
lines = sys.stdin.read().splitlines()
out = []
for line in lines:
    if '<<' in line:
        # include the line up to << (the redirect itself) but stop body ingestion
        out.append(line.split('<<')[0])
        break
    out.append(line)
print('\n'.join(out))
" 2>/dev/null)

# 1. Block git staging of secrets files (explicit filenames)
if echo "$BEFORE_HEREDOC" | grep -qE 'git add.*(\.env|\.key|\.pem|credentials|\.secret)'; then
  echo '{"decision":"block","reason":"Blocked: staging secrets file. These belong in .env.local (gitignored) or Vercel env vars, not in git."}'
  exit 0
fi

# 2. Block bulk git add that could sweep in .env files
if echo "$BEFORE_HEREDOC" | grep -qE 'git add\s+(-A|--all|-p|--patch|\.\s*$|\.\s*&&)'; then
  echo '{"decision":"block","reason":"Blocked: bulk git add can stage .env files. Stage specific files by name instead."}'
  exit 0
fi

# 3. Block ANY command that reads secrets files via Bash (use Read tool instead)
if echo "$COMMAND" | grep -qE '(cat|head|tail|less|more|bat|awk|sed|grep|perl|ruby|dd\s+if=|sort|tee|wc|strings|xxd|od)\s+.*\.(env|key|pem|secret)'; then
  echo '{"decision":"block","reason":"Blocked: use the Read tool for .env/secrets files, not Bash. Bash output may be cached or logged."}'
  exit 0
fi

# Also catch glob evasion like cat .e?v or cat .[e]nv
if echo "$COMMAND" | grep -qE '(cat|head|tail|less|more|bat|awk|sed|grep|perl)\s+.*\.e.v'; then
  echo '{"decision":"block","reason":"Blocked: possible glob evasion of .env file read. Use the Read tool instead."}'
  exit 0
fi

# 4. Block environment dumps (shell builtins + scripting languages)
if echo "$COMMAND" | grep -qE '^\s*(printenv|env|export|declare\s+-p|set)\s*($|\||>)'; then
  echo '{"decision":"block","reason":"Blocked: full environment dump exposes secrets. Reference specific vars in code instead."}'
  exit 0
fi

if echo "$COMMAND" | grep -qiE 'python3?\s+-c\s+.*os\.environ|node\s+-e\s+.*process\.env|ruby\s+-e\s+.*ENV'; then
  echo '{"decision":"block","reason":"Blocked: scripted environment dump. Reference specific vars in code instead."}'
  exit 0
fi

# 5. Block echo/printf of likely secret env vars (broad pattern: any var with KEY, SECRET, TOKEN, PASSWORD in the name)
if echo "$COMMAND" | grep -qiE '(echo|printf)\s+.*\$\{?\s*[A-Z_]*(KEY|SECRET|TOKEN|PASSWORD|CRED)[A-Z_]*'; then
  echo '{"decision":"block","reason":"Blocked: echoing secret env var. Reference by name in code, never print the value."}'
  exit 0
fi

# 6. Block curl/wget with inline Bearer tokens or API keys (literal values, not $VAR refs)
if echo "$COMMAND" | grep -qE "(Authorization: Bearer ['\"]?[a-zA-Z0-9_-]{10}|['\"]sk-[a-zA-Z0-9]|['\"]re_[a-zA-Z0-9]|['\"]xoxb-|['\"]ghp_[a-zA-Z0-9]|['\"]gho_[a-zA-Z0-9]|['\"]AIza[a-zA-Z0-9]|api[_-]?key['\"]?\s*[:=]\s*['\"][a-zA-Z0-9])" ; then
  echo '{"decision":"block","reason":"Blocked: inline secret in command. Use env var reference ($VAR) instead of the literal value."}'
  exit 0
fi

# 7. Block python/node reading .env files directly
if echo "$COMMAND" | grep -qiE "python3?\s+-c\s+.*open\(\s*['\"]\.env|node\s+-e\s+.*readFile.*\.env|ruby\s+-e\s+.*File\.read.*\.env"; then
  echo '{"decision":"block","reason":"Blocked: scripted .env file read. Use the Read tool instead."}'
  exit 0
fi

exit 0
