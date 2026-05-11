# File Writing

Where agent outputs go, why the path matters, and what the setup script does.

## Output location

All agent outputs land under `${CLAUDE_AGENT_RUNS:-~/claude-agent-runs}/spawn-team-runs/{run-id}/`. Each role has a subdirectory; each agent writes one file inside that subdirectory.

```
~/claude-agent-runs/spawn-team-runs/{run-id}/
├── researchers/
│   ├── researcher-1.md
│   ├── researcher-2.md
│   └── researcher-3.md
├── counters/
│   ├── counter-1.md
│   ├── counter-2.md
│   └── counter-3.md
├── contrarians/
│   ├── contrarian-1.md
│   ├── contrarian-2.md
│   └── contrarian-3.md
├── aggregator/
│   └── SYNTHESIS-draft.md
└── SYNTHESIS.md           <- final synthesis, written by lead
```

Subdirectory names match the role name in the agent's prompt. Agent file names follow the pattern `{role}-{N}.md`.

## Run-id format

`{YYYY-MM-DD}-{slug}-{HHMMSS}`

- `YYYY-MM-DD`: ISO date.
- `slug`: a short kebab-case task name (e.g., `cache-strategy`, `seo-audit`, `skill-test`). The lead picks the slug; keep it under 20 characters.
- `HHMMSS`: 24-hour time. Disambiguates multiple runs on the same date.

Example: `2026-05-04-cache-strategy-143022`

## Setup script

`scripts/setup-run-dir.sh` is the canonical way to create the run-dir. It:

1. Takes a task slug as the only argument.
2. Generates the run-id from the current date, the slug, and the current time.
3. Creates the run-dir and standard subdirectories.
4. Prints the absolute path of the run-dir to stdout.

Usage:

```bash
RUN_DIR=$(bash "${CLAUDE_PLUGIN_ROOT}/skills/spawn-agent-team/scripts/setup-run-dir.sh" cache-strategy)
echo "$RUN_DIR"
# ~/claude-agent-runs/spawn-team-runs/2026-05-04-cache-strategy-143022
```

The lead captures `$RUN_DIR` and substitutes it into every agent's prompt before spawning.

The script creates these subdirectories by default: `researchers`, `finders`, `counters`, `arguers`, `contrarians`, `aggregator`. If a custom team uses a different role name, create that subdirectory after running the script: `mkdir -p "$RUN_DIR/my-custom-role"`.

## Why NOT ~/.claude/

The Write tool is blocked when writing under `~/.claude/`, even with `--permission-mode bypassPermissions`. This is intentional: `~/.claude/` is a sensitive config path. Agents that try to write there will:

1. Get a write error from the tool, OR
2. Silently produce no file and return as if successful.

Either way, the synthesis fails because the output file is empty or missing. The setup script forces the run-dir to be outside `~/.claude/` to prevent this category of bug.

**Rule:** Never put `~/.claude/` in an agent's output path. Always use the run-dir from the setup script.

## Agent prompt requirements

Every agent's prompt must contain:

1. The absolute output file path (no relative paths, no `~/`).
2. An explicit `Write your output to: {absolute-path}` instruction.
3. Instructions to return only after writing the file.

Example prompt fragment:

```
Write your output to: /Users/yourname/claude-agent-runs/spawn-team-runs/2026-05-04-cache-strategy-143022/researchers/researcher-1.md
Return when done.
```

If the run-dir variable contains `~`, expand it before substituting into the prompt. Agents should always receive an absolute path with no `~` in it.

## Synthesis files

The aggregator writes its draft to `{RUN_DIR}/aggregator/SYNTHESIS-draft.md`.

The lead writes the final synthesis to `{RUN_DIR}/SYNTHESIS.md` (one level up). Two reasons:

1. The lead's final synthesis is the canonical output. The user reads it; downstream skills consume it.
2. Keeping the aggregator draft separate makes it easy to compare aggregator output to lead synthesis when reviewing how the run went.

If the aggregator failed, the lead writes only `{RUN_DIR}/SYNTHESIS.md` and adds the lead-only note (see `failure-modes.md`).

## Cleanup policy

Default: keep all run dirs. The user decides when to archive.

**Cold storage (monthly):** run-dirs older than 30 days can be moved from `${CLAUDE_AGENT_RUNS:-~/claude-agent-runs}/spawn-team-runs/` to a sibling `spawn-team-runs-archive/` directory. The archive directory is for cold-but-not-deleted data.

**Do not auto-delete.** Run outputs are evidence. They show what the team produced and how the synthesis was reached. Deleting them removes the audit trail.

If disk space becomes an issue, archive instead of delete. The archive follows the same `{run-id}/` directory structure.

## Disk and quota notes

A typical run-dir is small (10-100KB total across all agent outputs). 100 runs is roughly 10MB. Not a disk-pressure problem.

If a run produces unusually large outputs (e.g., agents wrote multi-megabyte transcripts because the brief asked for verbose output), the lead can compress the run-dir after synthesis: `tar -czf {RUN_DIR}.tar.gz {RUN_DIR}` then remove the original. This is rare; default is to leave it expanded for grep-ability.
