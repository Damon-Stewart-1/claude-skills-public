---
name: dispatch
description: Dispatch a task to a background Claude Code instance. Use when the user wants to kick off work without blocking the current session. Triggers on "dispatch", "background task", "run in background", "kick off", or "/dispatch".
user_invocable: true
---

# Dispatch: Background Claude Task Runner

The user wants to send a task to a separate Claude Code process running in the background.

## What to do

1. **Confirm the task.** Restate what the user wants done in one sentence. If unclear, ask.

2. **Pick permission tier.** Based on the task:
   - **Read-only** (research, summarize, explain): `"Read,Glob,Grep,Write,WebSearch,WebFetch"` (Write always included so output file can be created)
   - **Code** (fix bugs, write features, refactor): `"Read,Glob,Grep,Edit,Write,Bash(git diff *),Bash(git status *),Bash(npm test *),Bash(npx *)"`
   - **Full** (commits, installs, builds): `"Read,Glob,Grep,Edit,Write,Bash"`
   - **LLM review** (Gemini/ChatGPT): `"Read,Glob,Grep,Write,Bash"` (unrestricted Bash needed for `source ~/.api-keys-cache`)
   - Default to read-only unless the task clearly requires writes. Ask if unsure.

3. **Pick model.** For research, summaries, file searches, and template writes, add `--model sonnet`. Use Opus (default) for architecture, client-facing copy, and multi-step reasoning.

4. **Pick LLM target.** Ask the user which LLM to dispatch to (default: Claude). For Gemini/ChatGPT details, read `references/multi-llm-dispatch.md`.

5. **Set guardrails.** Always set `--max-turns` (default 25, down for simple tasks, up to 40 for large). Set timeout: 600s simple, 1800s medium, 3600s complex.

6. **Build and run.** Generate job ID and write the prompt to a temp file, then launch the script:

```bash
JOB_ID="job-$(date +%Y%m%d-%H%M%S)"
PROMPT_FILE="/tmp/${JOB_ID}-prompt.txt"

# Write full task prompt to file (include file paths, project context, done criteria)
cat > "$PROMPT_FILE" << 'PROMPT'
<the user's task prompt>
PROMPT

# Launch in background
(bash ~/.claude/skills/dispatch/scripts/dispatch.sh \
  "$JOB_ID" "$PROMPT_FILE" "<TOOLS>" <MAX_TURNS> <TIMEOUT_SECS> [MODEL] [ADD_DIR]) &

echo "Dispatched ${JOB_ID} (PID: $!)"
```

Run with `run_in_background: false` since the subshell backgrounds via `&` and returns immediately.

7. **Report back.** Tell the user: job ID, what it's doing, turn limit, how to check (`/jobs`).

## Why /tmp/ for output

`~/.claude/` is a sensitive write path. Claude Code blocks the Write tool there even with `--permission-mode bypassPermissions`. The dispatch script writes to `/tmp/` first, then copies to `~/.claude/jobs/` via shell after completion.

For tasks needing multiple output files, direct the spawned Claude to `~/Claude-Stuff/` or a project directory.

## Important

- If the task involves a specific project directory, pass it as the ADD_DIR argument.
- Never dispatch tasks that need user judgment mid-execution.
- Never dispatch tasks that touch production systems, push code, or send external messages.
- The background Claude has NO access to this conversation's context. Include everything it needs in the prompt.
- Do NOT use `--bare` flag (breaks keychain auth).
- Tell spawned Claude to target `/tmp/` or `~/Claude-Stuff/` for writes, never `~/.claude/`.
