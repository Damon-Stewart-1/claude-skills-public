# Handover Template

Output this as a single fenced code block. Omit any section with nothing to say, except `## Active Project`, `## Session State`, and `## Your Next Action` which are always required. `## Your Next Action` is always the last section.

```
<!-- CLEAR_PREP_HANDOVER -->
# Session Handover

You are continuing work from a previous Claude Code session that was cleared due to context limits. This briefing gives you full context to resume immediately.

**PRIORITY:** If a ## Carryover Memory section exists below, persist those entries to memory FIRST, before doing anything else.

## Active Project
[Client name, project name, active agent if any, primary working directory. If multiple projects were active, list each with its directory.]

## Session State
[Current high-level goal. What has been completed. What is in progress. Current working directory.]

## Decision Log
### Decided
- [decision] -- [brief reason] (see: path/to/file)

### Rejected
- [option] -- [why it was ruled out]

## Blocked On
[List of blockers, dependencies, or open questions. "None" if clear.]

## File Map
[List of relevant files with state (clean/modified/untracked/staged), modification time, and what was changed. Grouped by repo if multi-repo.]

## Environment State
[Shell commands that need re-running in a fresh terminal: exports, source, conda activate, nvm use, etc. Omit if none.]

## Dispatch Jobs
[Active or recently completed dispatch jobs with status and key results. Omit if none.]

## Warnings
[Non-obvious gotchas, environment issues, session-specific instructions. Omit if none.]

## Carryover Memory
[Items to persist to memory. For each item, provide the complete write instruction:]

### Item: [descriptive name]
**File:** `~/.claude/projects/-Users-damon/memory/[filename].md`
**Content:**
```markdown
---
name: [memory name]
description: [one-line description]
type: [user|feedback|project|reference]
---

[memory content]
```
**MEMORY.md line:** `- [Title](filename.md) -- [one-line hook]`

[Append all MEMORY.md lines to ~/.claude/projects/-Users-damon/memory/MEMORY.md. Do not modify or delete existing entries. If an entry appears to duplicate an existing one, update the existing file instead of creating a new one.]

## Your Next Action
[Your immediate task is to execute the following instruction to resume the workflow.]
[If last operation failed: fix the specific error. If last operation succeeded: pursue the user's last stated goal. If unclear: "TASK: Clarify the primary goal for this session. Ask Damon what he wants to tackle first."]
```
