#!/usr/bin/env bash
# block-writes-until-review-read.sh
# (formerly review-ack-guard.sh)
# PreToolUse hook: blocks Write/Edit on implementation files when an in-review
# plan references a dispatch job whose review output has not been acknowledged.
# Acknowledge by reading the review, then: touch ~/.claude/reviews-read/{job-id}.ack

set -uo pipefail

PLANS_DIR="${HOME}/.claude/plans"
ACK_DIR="${HOME}/.claude/reviews-read"
mkdir -p "$ACK_DIR" 2>/dev/null

# Read tool input from stdin (Claude Code hook contract)
INPUT="$(cat)"

# Extract tool name and target file path. Use python for reliable JSON parsing.
read -r TOOL_NAME FILE_PATH <<<"$(python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    tool = data.get("tool_name", "")
    tin = data.get("tool_input", {}) or {}
    fp = tin.get("file_path") or tin.get("filename") or ""
    print(f"{tool}\t{fp}")
except Exception:
    print("\t")
' <<<"$INPUT" | tr '\t' ' ')" 2>/dev/null || exit 0

# Only act on Write/Edit/MultiEdit
case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

# Only block implementation files. Skip plan files, memory files, markdown, etc.
case "$FILE_PATH" in
  *.html|*.js|*.jsx|*.ts|*.tsx|*.py|*.sh|*.css|*.scss) ;;
  *) exit 0 ;;
esac

# Skip if no plans dir
[ -d "$PLANS_DIR" ] || exit 0

# Find plans currently in review and harvest job IDs they reference.
# Plan format: YAML frontmatter with `status: in-review`, body mentions job-YYYYMMDD-HHMMSS.
UNACKED=""
while IFS= read -r -d '' plan; do
  # Check frontmatter for status: in-review (case-insensitive, within first 30 lines)
  if ! head -n 30 "$plan" 2>/dev/null | grep -qiE '^status:[[:space:]]*in-review' ; then
    continue
  fi
  # Extract job IDs (job-YYYYMMDD-HHMMSS format)
  JOBS=$(grep -oE 'job-[0-9]{8}-[0-9]{6}' "$plan" 2>/dev/null | sort -u)
  for job in $JOBS; do
    if [ ! -f "${ACK_DIR}/${job}.ack" ]; then
      # Try to locate the review output file
      OUTPUT=""
      for candidate in \
          "${HOME}/Claude-Stuff/review-"*"${job}"*.md \
          "${HOME}/.claude/jobs/${job}.md" \
          "${HOME}/Claude-Stuff/"*"${job}"*.md ; do
        if [ -f "$candidate" ]; then
          OUTPUT="$candidate"
          break
        fi
      done
      [ -z "$OUTPUT" ] && OUTPUT="(check ~/Claude-Stuff/ or ~/.claude/jobs/${job}.md)"
      UNACKED="${UNACKED}${job}|${OUTPUT}|${plan}\n"
    fi
  done
done < <(find "$PLANS_DIR" -maxdepth 2 -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)

if [ -n "$UNACKED" ]; then
  echo "REVIEW NOT ACKNOWLEDGED:" >&2
  printf '%b' "$UNACKED" | while IFS='|' read -r job output plan; do
    [ -z "$job" ] && continue
    echo "  Job ${job} output at ${output} has not been read this session." >&2
    echo "  Plan: ${plan}" >&2
    echo "  Read the review, then: touch ${ACK_DIR}/${job}.ack" >&2
    echo "" >&2
  done
  exit 2
fi

exit 0
