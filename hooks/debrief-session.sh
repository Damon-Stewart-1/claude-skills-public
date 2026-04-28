#!/bin/bash
# Stop hook: spawns background Haiku analysis of session transcript.
# Exits 0 immediately so session teardown is not delayed.

# Read ALL stdin before forking — pipe closes on parent exit
input=$(cat)

# Recursion guard
if [[ "$(echo "$input" | jq -r '.stop_hook_active // false')" == "true" ]]; then
  exit 0
fi

TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')

[[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]] && exit 0

LOG=~/Claude-Stuff/debrief-errors.log
CANDIDATES=~/Claude-Stuff/debrief-candidates.md
mkdir -p ~/Claude-Stuff

# Spawn analysis in background with all values already bound
(
  # Skip trivial sessions (< 4 user+assistant turns)
  turn_count=$(DEBRIEF_TRANSCRIPT="$TRANSCRIPT_PATH" python3 -c "
import json, sys, os
lines = [l.strip() for l in open(os.environ['DEBRIEF_TRANSCRIPT']) if l.strip()]
print(sum(1 for l in lines if json.loads(l).get('type') in ('user','assistant')))
" 2>/dev/null || echo 0)

  if [[ "$turn_count" -lt 4 ]]; then
    exit 0
  fi

  # Extract readable text only — skip tool calls, JSON blobs, system-reminders
  transcript_text=$(DEBRIEF_TRANSCRIPT="$TRANSCRIPT_PATH" python3 - << 'PYEOF'
import json, sys, re, os

path = os.environ['DEBRIEF_TRANSCRIPT']
with open(path) as f:
    lines = [l.strip() for l in f if l.strip()]

out = []
for line in lines:
    try:
        d = json.loads(line)
        if d.get('type') not in ('user', 'assistant'):
            continue
        role = d['message']['role'].upper()
        content = d['message'].get('content', '')

        if isinstance(content, list):
            texts = []
            for c in content:
                if isinstance(c, dict) and c.get('type') == 'text':
                    t = c.get('text', '').strip()
                    t = re.sub(r'<system-reminder>.*?</system-reminder>', '', t, flags=re.DOTALL)
                    t = re.sub(r'<critical-instruction>.*?</critical-instruction>', '', t, flags=re.DOTALL)
                    t = t.strip()
                    if t:
                        texts.append(t[:2000])
            text = '\n'.join(texts)
        else:
            text = re.sub(r'<[^>]+>.*?</[^>]+>', '', str(content), flags=re.DOTALL).strip()[:2000]

        if text and len(out) < 40:
            out.append(f'[{role}]: {text}')
    except Exception:
        pass

print('\n\n'.join(out))
PYEOF
)

  if [[ -z "$transcript_text" ]]; then
    echo "[$(date)] Session $SESSION_ID: no extractable text, skipping" >> "$LOG"
    exit 0
  fi

  # Build plugin file index (paths only — not content)
  plugin_index=$(find ~/ei-claude-plugin -type f \( -name "*.sh" -o -name "*.md" -o -name "*.txt" \) | sort | head -150)

  # Write prompt to temp file
  tmpfile=$(mktemp /tmp/debrief-XXXXXX.txt)
  cat > "$tmpfile" << EOF
SESSION: $SESSION_ID
DATE: $(date '+%Y-%m-%d %H:%M')

TRANSCRIPT:
$transcript_text

EXISTING PLUGIN FILES (paths only):
$plugin_index
EOF

  # Init Homebrew PATH so claude binary is findable in background subshell
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

  result=$(cat "$tmpfile" | claude -p \
    --system-prompt "$(cat ~/ei-claude-plugin/prompts/debrief-analyst.txt)" \
    --model haiku \
    --output-format text \
    --no-session-persistence \
    2>> "$LOG")

  exit_code=$?
  rm -f "$tmpfile"

  if [[ $exit_code -ne 0 || -z "$result" ]]; then
    echo "[$(date)] Session $SESSION_ID: claude subprocess failed (exit $exit_code)" >> "$LOG"
    exit 0
  fi

  if [[ "$result" == "No gaps found." ]]; then
    exit 0
  fi

  # Write to session-specific temp, then atomically append
  session_tmp=$(mktemp /tmp/debrief-out-XXXXXX.md)
  {
    echo ""
    echo "---"
    echo "## Session: $SESSION_ID ($(date '+%Y-%m-%d %H:%M'))"
    echo ""
    echo "$result"
  } > "$session_tmp"

  cat "$session_tmp" >> "$CANDIDATES"
  rm -f "$session_tmp"

) >> "$LOG" 2>&1 &

exit 0
