# Planning Gotchas

Pitfalls observed in past planning sessions. Read this before writing any plan.

## Architecture Assumptions
- **Don't assume auto-discovery paths work.** Verify that `~/.claude/agents/`, `~/.claude/commands/`, `~/.claude/skills/` actually auto-discover before relying on them. Check existing working examples.
- **Don't assume plugin commands aren't namespaced.** Plugin commands may register as `plugin-name:command-name`, not just `command-name`. Verify before deleting user-level duplicates.
- **Hook event timing matters.** PreToolUse = prevention (blocks before write). PostToolUse = detection (content already on disk). Use PreToolUse when you want to prevent bad content, PostToolUse when you want to flag it after the fact.

## Scope Creep
- **Plans grow during execution.** Build in slack. If you estimate 5 phases, the user will add requirements mid-stream.
- **"While we're at it" is the enemy.** Each phase should do ONE thing. If you catch yourself adding unrelated improvements, make them a separate phase or a follow-up plan.

## Permissions & Config
- **Bash permissions are prefix-matched.** `Bash(claude:*)` matches any command starting with "claude". `Bash(claude plugin:*)` only matches commands starting with "claude plugin". Removing the broader pattern breaks commands that depend on it.
- **CronCreate is session-only.** Jobs expire when Claude exits (max 7 days). Don't use it for persistent scheduled tasks.
- **Stop hooks (prompt-type) fire on EVERY response.** They add latency and token cost. Use sparingly. Consider command-type hooks with keyword filtering instead.

## File Operations
- **Always back up before mass operations.** `tar czf ~/Desktop/backup.tar.gz <dir>` before deleting, moving, or rewriting config files.
- **Shell variable comparison in loops can silently fail.** Test your keep/archive logic on a small set before running on the full list.
- **Trailing commas in JSON.** When removing entries from JSON files (like .mcp.json), check for trailing commas that would break parsing.

## Verification
- **Completion promises must be copy-pasteable.** The user (or Ralph) should be able to run them without modification.
- **Test the verification command BEFORE writing it into the plan.** A verification that itself fails is worse than no verification.
- **Count what matters.** "Expected: ~26 commands" is less useful than "Expected: 26 commands, 0 missing descriptions."
