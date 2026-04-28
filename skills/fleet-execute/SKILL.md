---
name: fleet-execute
description: "Execute READY plans from the fleet triage queue. Shows which plans scored ready, asks for confirmation, then dispatches agents. Triggers on: /fleet-execute, 'run fleet', 'execute ready plans', 'dispatch fleet', 'run the fleet'."
user_invocable: true
---

# /fleet-execute: Plan Fleet Dispatcher

Dispatches autonomous agents to execute plans that scored READY in the last triage run.

## Prerequisites

This skill requires a fleet infrastructure to be set up first:

- `~/Claude-Stuff/fleet/`: output directory for triage data and run logs
- `~/bin/fleet-triage.sh`: scores plans in `~/.claude/plans/` against 4 criteria (acceptance, no-human-needed, explicit-paths, idempotency), outputs `triage-latest.json`
- `~/bin/fleet-execute.sh`: reads triage output and dispatches background Claude agents per READY plan

These scripts are not included here. Build them to match your plan format, or ask Claude to generate them once you have plans in `~/.claude/plans/`.

## What to do

1. **Check triage data.** Read `~/Claude-Stuff/fleet/triage-latest.json` and `~/Claude-Stuff/fleet/last-triage.json`. If neither file exists or triage is more than 12 hours old, tell the user and suggest running `~/bin/fleet-triage.sh` first.

2. **Show READY plans.** Display each plan that scored READY (score 10-12 out of 12), with:
   - Plan name
   - Score (X/12)
   - Per-criterion breakdown (acceptance / no-human / paths / idempotency)
   - One-sentence summary
   - Any noted blockers

3. **Confirm with user.** Ask: "Ready to dispatch agents for these N plans? (yes/no, or name specific plans to skip)"

4. **On confirmation:** Run:
   ```bash
   ~/bin/fleet-execute.sh
   ```
   Do NOT pass `--autonomous`. Interactive mode only.

5. **Tell the user:**
   - Run output lands at: `~/Claude-Stuff/fleet/runs/{date}-{time}/`
   - Escalations go to: `~/Claude-Stuff/fleet/needs-human.md`

6. **After completion:** Read the latest `~/Claude-Stuff/fleet/runs/*/summary.md` and report: how many completed, how many escalated.

## Stale triage handling

If `last-triage.json` is missing or triage was more than 12 hours ago:

> "No recent triage data (last run: {date} or never). Run `~/bin/fleet-triage.sh` manually or wait for your scheduled triage job. Triage takes 2-5 minutes."

## Hold file

To cancel execution without running this skill:
```bash
touch ~/Claude-Stuff/fleet/hold
# or for a specific date:
touch ~/Claude-Stuff/fleet/hold-$(date +%Y-%m-%d)
```

## Dry run

To see what would be dispatched without running agents:
```bash
~/bin/fleet-execute.sh --dry-run
```

## Execution parameters (adjust to taste)

- Agents run with `--allowedTools "Read,Glob,Grep,Edit,Write"` (no Bash by default; add it if your plans need shell commands)
- Recommended per-agent timeout: 30 minutes
- Recommended max concurrent agents: 2
- Failed or blocked agents should escalate to `needs-human.md`

## Scheduling (optional)

A launchd plist (macOS) or cron job can run `fleet-triage.sh` on a schedule (e.g. 8 AM daily) to pre-score plans. The execute step should remain manual so you always confirm before dispatching agents.
