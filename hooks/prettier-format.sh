#!/usr/bin/env bash
# PostToolUse hook: run Prettier on supported files after Edit/Write/MultiEdit

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path
[ -z "$FILE_PATH" ] && exit 0

# Only format matching extensions
case "$FILE_PATH" in
  *.ts|*.html|*.css|*.json) ;;
  *) exit 0 ;;
esac

# Only format if file exists
[ -f "$FILE_PATH" ] || exit 0

# Only run if prettier is available in the project
if command -v npx &>/dev/null && [ -f "$(dirname "$FILE_PATH")/node_modules/.bin/prettier" ] || npx prettier --version &>/dev/null 2>&1; then
  npx prettier --write "$FILE_PATH" >/dev/null 2>&1 || true
fi

exit 0
