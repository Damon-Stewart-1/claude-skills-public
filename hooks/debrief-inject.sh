#!/bin/bash
# SessionStart hook: surfaces pending debrief proposals into opening context.
# Archives the file after reading so it does not repeat.

input=$(cat)
source=$(echo "$input" | jq -r '.source // empty')

# Only on fresh startup, not resume/compact/clear
[[ "$source" != "startup" ]] && exit 0

debrief_file=~/Claude-Stuff/debrief-candidates.md
[[ ! -f "$debrief_file" || ! -s "$debrief_file" ]] && exit 0

echo "=== PENDING PLUGIN DEBRIEF PROPOSALS ==="
echo ""
echo "The following changes were proposed by the debrief system based on recent sessions."
echo "These are PROPOSALS only. To apply one: read the file it targets, then use Edit/Write."
echo "To dismiss all: rm ~/Claude-Stuff/debrief-candidates.md"
echo ""
cat "$debrief_file"
echo ""
echo "=== END DEBRIEF PROPOSALS ==="

# Archive with timestamp including seconds to avoid same-day overwrite
mv "$debrief_file" ~/Claude-Stuff/debrief-candidates.applied.$(date +%Y%m%d%H%M%S).md
