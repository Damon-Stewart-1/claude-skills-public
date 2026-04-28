# /dispatch

Sends a task to a background Claude process so it runs without blocking your current session.

## What it does

Spawns a separate `claude` CLI process with a scoped set of tools, a turn limit, and a timeout. The job runs in the background; you keep working. Check status with `/jobs`.

Useful for: research tasks, file rewrites, plan reviews, long refactors, anything where you don't need to watch it run.

## Invoke

```
/dispatch
```

Describe the task in plain language. Claude will confirm it, pick a permission tier, set a turn limit, and launch.

## Permission tiers

| Tier | Tools | Use for |
|------|-------|---------|
| Read-only | Read, Glob, Grep, Write, WebSearch, WebFetch | Research, summaries, analysis |
| Code | + Edit, limited Bash (git, npm, npx) | Bug fixes, feature writes, refactors |
| Full | + unrestricted Bash | Commits, installs, builds |

Write is always included so the job can save its output.

## Output

Jobs write output to `~/.claude/jobs/<job-id>.md`. The job ID is returned when the task is dispatched. Use `/jobs` to list and inspect running or completed jobs.

## Setup

Requires the `dispatch.sh` script bundled at `skills/dispatch/scripts/dispatch.sh`. Place it somewhere on your path or reference it directly. The script expects:

```
dispatch.sh <job-id> <prompt-file> <tools> <max-turns> <timeout-secs> [model] [working-dir]`
```

The Claude Code CLI must be on your PATH as `claude`.

## Notes

- The background process has no access to your current conversation. The prompt must be fully self-contained -- file paths, project context, done criteria, all of it.
- Never dispatch tasks that need judgment mid-execution, touch production systems, push code, or send external messages.
- For tasks that need multiple output files, direct the spawned Claude to a project directory rather than `~/.claude/`.
