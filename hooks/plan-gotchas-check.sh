#!/bin/bash
# PreToolUse hook: When writing to ~/.claude/plans/, remind Claude to
# cross-check against gotchas before finalizing.
# Fires on all Write calls, filters internally to plans/ path only.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

if [[ "$FILE_PATH" == "$HOME/.claude/plans/"* ]]; then
  echo "REMINDER: Before finalizing this plan, read ~/.claude/skills/plan/gotchas.md and verify:"
  echo "- Completion promises are copy-pasteable bash commands"
  echo "- Phases are independently verifiable"
  echo "- No architecture assumptions are untested"
  echo "- Verification commands have been tested before inclusion"
fi
