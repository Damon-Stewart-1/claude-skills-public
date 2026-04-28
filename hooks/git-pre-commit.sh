#!/usr/bin/env bash
# Git pre-commit hook: typecheck + lint staged .ts files
# Install per-repo: cp ~/ei-claude-plugin/hooks/git-pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -euo pipefail

# Check for staged .ts files
STAGED_TS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ts$' || true)

if [ -z "$STAGED_TS" ]; then
  exit 0
fi

echo "Running TypeScript check..."
if ! npx tsc --noEmit; then
  echo "TypeScript errors found. Fix before committing."
  exit 1
fi

echo "Running ESLint..."
if ! npx eslint --ext .ts $STAGED_TS; then
  echo "ESLint errors found. Fix before committing."
  exit 1
fi

exit 0
