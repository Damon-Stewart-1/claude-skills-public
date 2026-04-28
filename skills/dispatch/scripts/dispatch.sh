#!/usr/bin/env bash
# dispatch.sh - Background Claude task runner
#
# Usage: dispatch.sh <JOB_ID> <PROMPT_FILE> <TOOLS> <MAX_TURNS> <TIMEOUT_SECS> [MODEL] [ADD_DIR]
#
# Arguments:
#   JOB_ID        - Job identifier (e.g., job-20260305-143022)
#   PROMPT_FILE   - Path to file containing the full task prompt
#   TOOLS         - Quoted tool list for --allowedTools
#   MAX_TURNS     - Maximum conversation turns
#   TIMEOUT_SECS  - Timeout in seconds (600 simple, 1800 medium, 3600 complex)
#   MODEL         - Optional: opus|sonnet|haiku (default: opus)
#   ADD_DIR       - Optional: additional directory to add via --add-dir
#
# Why unset CLAUDECODE: prevents "nested Claude" errors when spawning from inside Claude Code.
# Why eval brew shellenv: Claude Code caches shell env at session start; gtimeout (coreutils)
# may not be on PATH without reinitializing Homebrew.

set -euo pipefail

JOB_ID="${1:?Missing JOB_ID}"
PROMPT_FILE="${2:?Missing PROMPT_FILE}"
TOOLS="${3:?Missing TOOLS}"
MAX_TURNS="${4:?Missing MAX_TURNS}"
TIMEOUT_SECS="${5:-1800}"
MODEL="${6:-}"
ADD_DIR="${7:-}"

TMP_OUTPUT="/tmp/${JOB_ID}.md"
FINAL_OUTPUT="$HOME/.claude/jobs/${JOB_ID}.md"
LOG_FILE="$HOME/.claude/jobs/${JOB_ID}.log"

mkdir -p "$HOME/.claude/jobs"

# Write job metadata
cat > "$HOME/.claude/jobs/${JOB_ID}.meta" << META
status: running
task: $(head -1 "$PROMPT_FILE" | cut -c1-80)
model: ${MODEL:-opus}
started: $(date '+%Y-%m-%d %H:%M:%S')
output: ${FINAL_OUTPUT}
tools: ${TOOLS}
max_turns: ${MAX_TURNS}
META

PROMPT="$(cat "$PROMPT_FILE")"

# Build claude command
CMD=(claude -p "$PROMPT" --allowedTools "$TOOLS" --max-turns "$MAX_TURNS" --output-format json)
CMD+=(--append-system-prompt "Write your final output to ${TMP_OUTPUT}. Be thorough but concise.")
CMD+=(--no-session-persistence)

if [ -n "$MODEL" ]; then
  CMD+=(--model "$MODEL")
fi
if [ -n "$ADD_DIR" ]; then
  CMD+=(--add-dir "$ADD_DIR")
fi

# Launch (caller backgrounds this script via & or run_in_background)
unset CLAUDECODE

# Re-initialize Homebrew so gtimeout (coreutils) is on PATH in background subshells.
# Claude Code caches shell env at session start; subshells don't inherit it.
for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$brew_path" ]; then
    eval "$("$brew_path" shellenv)"
    break
  fi
done

gtimeout "${TIMEOUT_SECS}" "${CMD[@]}" > "$LOG_FILE" 2>&1
EXIT_CODE=$?

# Post-completion: move output from /tmp/ to jobs dir
if [ -f "${TMP_OUTPUT}" ]; then
  cp "${TMP_OUTPUT}" "${FINAL_OUTPUT}"
  rm -f "${TMP_OUTPUT}"
else
  # Fallback: extract from JSON log (check permission_denials first, then result)
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    data = json.load(open('${LOG_FILE}'))
    content = ''
    for d in data.get('permission_denials', []):
        if d.get('tool_name') == 'Write':
            c = d.get('tool_input', {}).get('content', '')
            if len(c) > len(content):
                content = c
    if not content:
        content = data.get('result', '') or data.get('response', '') or str(data)
    if content:
        with open('${FINAL_OUTPUT}', 'w') as f:
            f.write(content)
except: pass
" 2>/dev/null
  fi
fi

# Determine final status (exit 124 = gtimeout killed the process)
if [ "$EXIT_CODE" -eq 124 ]; then
  STATUS="timed_out"
elif [ "$EXIT_CODE" -ne 0 ]; then
  STATUS="failed"
elif [ ! -f "${FINAL_OUTPUT}" ]; then
  STATUS="failed"
else
  STATUS="complete"
fi

# Update meta
sed -i '' "s/status: running/status: ${STATUS}/" "$HOME/.claude/jobs/${JOB_ID}.meta"
echo "exit_code: ${EXIT_CODE}" >> "$HOME/.claude/jobs/${JOB_ID}.meta"
echo "completed: $(date '+%Y-%m-%d %H:%M:%S')" >> "$HOME/.claude/jobs/${JOB_ID}.meta"
