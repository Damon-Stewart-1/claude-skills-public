---
name: leadership-plan-week
description: Sunday weekly planning interview that produces a WEEK_DATA JSON file with threads, day blocks, win conditions, delegations, and pushed-off items. Triggers on "/leadership-plan-week", "weekly planning", "Sunday plan", "plan my week", "weekly plan interview". Pulls Productive overdue + due-this-week. Threads-first, day-second cognition. Resumable mid-conversation.
user_invocable: true
---

# /plan-week — Weekly Planning Interview

Sunday evening (or any midweek refactor) interview with Damon. Produces a `WEEK_DATA` JSON file at `~/.claude/notes/scratch/weekly-plan-{weekStart}.json`. Phase 0 of the larger Weekly Plan Command Center system. No KV, no Gmail, no Slack, no page rendering — pure local file output.

## Modes

```
/plan-week               # Sunday full week interview (default)
/plan-week --reflow      # Midweek: read current week's WEEK_DATA, ask "what changed since {last update}?", reflow days from today onward
/plan-week --resume      # Force resume from existing draft, skip the prompt
/plan-week --restart     # Force fresh start, delete any existing draft
```

If a draft exists at `~/.claude/notes/scratch/weekly-plan-draft-{weekStart}.json` and no mode flag forces a path, ask: "Draft from Phase N exists for week of {weekStart}. Resume or restart?"

## What to Do

### Phase 1 — Pull context (silent, parallel where possible)

1. Compute `weekStart` (most recent Sunday in ISO date format) and `lastWeekStart` (Sunday before that).
2. Read `~/.claude/notes/scratch/weekly-plan-{lastWeekStart}.json` if it exists. Extract: previous threads, win conditions, delegations, pushedOff, taskPool. Use as carry-forward defaults.
3. Read `~/.claude/notes/scratch/quarterly-wins-{currentQuarter}.json` if it exists. Format: `2026-Q2`. Surface in Phase 2.
4. Read `~/.claude/notes/scratch/productive-client-map.json` if it exists. Used to map Productive project names to client names.
5. Pull Productive overdue + due-this-week tasks. Pattern:

```bash
source ~/.claude/productive.env.local

YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
WEEK_END=$(date -v+7d +%Y-%m-%d)

# Filter syntax: range form (..), status integers (1=open, 2=in_progress), assignee_id required for personal scope.
# Damon's person ID = 540851. Do NOT use filter[due_date_lte/gte] or filter[status_id] - they return unsupported_filter errors.

# Overdue
printf 'header = "Content-Type: application/vnd.api+json"\nheader = "X-Auth-Token: %s"\nheader = "X-Organization-Id: 31234"\n' "${PRODUCTIVE_API_TOKEN}" | \
  curl -s --globoff --max-time 10 --config - -X GET \
  "https://api.productive.io/api/v2/tasks?filter[due_date]=2025-01-01..${YESTERDAY}&filter[assignee_id]=540851&filter[status]=1,2&include=project&page[size]=100"

# Due this week
printf 'header = "Content-Type: application/vnd.api+json"\nheader = "X-Auth-Token: %s"\nheader = "X-Organization-Id: 31234"\n' "${PRODUCTIVE_API_TOKEN}" | \
  curl -s --globoff --max-time 10 --config - -X GET \
  "https://api.productive.io/api/v2/tasks?filter[due_date]=${TODAY}..${WEEK_END}&filter[assignee_id]=540851&filter[status]=1,2&include=project&page[size]=100"
```

If `productive.env.local` does not exist, ask Damon for the API token at runtime. Store in shell variable for the session only. Do not write it to disk.

10s timeout per pull. One retry on failure. If still failing, continue with warning: "Productive pull failed, manually surface anything overdue."

For each Productive task returned, map `project.name` → `client` via the client-map file. If a project name is not in the map, ask Damon once: "Productive project '{name}' — which client does this map to?" Persist answer to the map file.

After Phase 1 completes, write interim state to `~/.claude/notes/scratch/weekly-plan-draft-{weekStart}.json` with a `phase: 1` marker.

### Phase 2 — Surface patterns (no questions, just observations)

Print a context summary in this shape:

```
Last week ({lastWeekStart}):
- Threads with no movement: [list of clients from last week's threads array that don't appear in completion log]
- Tasks carried forward (incomplete): [count + summary]
- Quarterly wins ({currentQuarter}): {amazing} (or "NOT SET — synthetic P1 will be injected")

Productive this week:
- Overdue: {count} tasks across {client_count} clients
- Due this week: {count} tasks across {client_count} clients

Heads up:
- {Quarter rollover trigger if today >= 15th of month preceding quarter end}
- {Other surfaced observations}
```

This is observation only. No questions. Damon reads, then we move to Phase 3.

Write interim state with `phase: 2` marker.

### Phase 3 — Threads-first interview

This is the most important design decision. Walk client-by-client BEFORE walking days. Damon thinks in threads first, days second.

Active threads = union of:
- Clients with overdue or due-this-week Productive tasks
- Clients in last week's `threads` array
- Standard set: Zenith, Dr. Adam, AND, Pinx, Kamari, Synchrony, ICSW, Earned Impact Internal

For each thread, ask:
> "{Client}. What moves this week?"

Capture as a list of moves with priority (P1, P2, P3, D for delegate). Damon may answer "nothing" — that's a valid answer, skip the thread.

After all threads gathered, confirm the permanent frame in one line:
> "Frame: Mon no external meetings except cofounders, Wed quiet, Fri hard stop noon, Sun 4hr quiet. Mornings 07-11 deep work. Email sweeps 11/15/16:30. Adjustments?"

Apply default frame unless Damon overrides.

Then for each move, ask "where in the week?":
> "Where in the week does '{move}' land?"

Damon can answer with a day (Mon, Tue, etc.), a time block (Mon 07-10), or "task pool" (no specific day yet). Build the `days` array and `taskPool` array from these answers.

Write interim state with `phase: 3` marker.

### Phase 4 — Win conditions, delegations, pushed-off (consolidated)

Show all three at once. Single consolidated response per section.

Win conditions — show last week's three categories:
> "Last week's win conditions:
> Client: {text}
> BizDev: {text}
> Team: {text}
> For each, carry, edit, or replace?"

Damon responds with one block:
```
Client: carry
BizDev: edit -> "new text"
Team: replace -> "new text"
```

Delegations — show all open delegations:
> "Open delegations:
> Kaelene: {task} (status: Waiting, last touched {date})
> Abigail: {task} (status: Assigned, last touched {date})
> Fida: {task} (status: Waiting, last touched {date})
> Status update on each in one response. Add new rows if needed."

Damon responds with status updates. New delegations get added to the array with status "Assigned" and lastTouchedAt of now.

Pushed-off:
> "What's deferred this week?"

Damon lists items.

Write interim state with `phase: 4` marker.

### Phase 5 — Final review

Print the full WEEK_DATA in human-readable prose form before approval. Format:

```
WEEK OF {weekLabel}
Mode: {mode}
Quarter: {quarterlyWinsRef}

WIN CONDITIONS
Client: {text}
BizDev: {text}
Team: {text}

THREADS THIS WEEK
{client} ({priority}): {move 1}, {move 2}, ...
...

DAYS
SUN {date}: {block.time} {block.label} ({client}, {priority})
              {block.notes}
...

TASK POOL ({count})
{label} ({client}, {priority})
...

DELEGATIONS ({count})
{owner} ({client}): {task} [{status}, last touched {date}]
...

PUSHED OFF ({count})
{item}
...

FRAME
{frame line 1}
...
```

Then ask:
> "Approve and write to weekly-plan-{weekStart}.json? (yes / edit / cancel)"

If edit, ask which section to edit, return to that phase.
If cancel, leave draft in place, exit.
If yes, proceed to Phase 6.

### Phase 6 — Write final + cleanup

1. Write WEEK_DATA to `~/.claude/notes/scratch/weekly-plan-{weekStart}.json`. Include `version: 1`, `createdAt: {ISO timestamp}`.
2. Delete `~/.claude/notes/scratch/weekly-plan-draft-{weekStart}.json`.
3. Print: "Written to ~/.claude/notes/scratch/weekly-plan-{weekStart}.json"

### Phase 7 — Quarter rollover check

1. Compute current quarter (e.g., 2026-Q2) and quarter end month (Q2 ends Jun 30).
2. Compute trigger date = 15th of month preceding quarter end month (Q2 trigger = May 15).
3. If today >= trigger date AND `~/.claude/notes/scratch/quarterly-wins-{nextQuarter}.json` does not exist:
   > "Quarter {currentQuarter} ends in {N} weeks. Run /plan-quarter now or this Sunday's plan will hold a placeholder. Inject synthetic P1 task into next week pool? (yes / no)"
4. If yes, append to next-week placeholder: `{id: "p1-quarter-rollover", label: "Run /plan-quarter to set {nextQuarter} wins", client: "Earned Impact Internal", priority: "P1"}`.
5. Print: "Phase 7 complete."

If quarterly wins for the current quarter were never set when this run started, also inject the same synthetic task into THIS week's pool before Phase 6 writes the file.

## Reflow Mode (--reflow)

If invoked with `--reflow`, behavior changes:

1. Skip Phase 1 last-week pull (read CURRENT week's WEEK_DATA instead).
2. Phase 2: surface "what's done since the last update vs. what's still open this week."
3. Phase 3: ask "what changed?" Damon describes the trigger (e.g., "Cole crisis blew up Tuesday"). Skill walks remaining days from today onward, threads-first.
4. Phases 4-6 unchanged. Updates the same WEEK_DATA file in place, bumps `version`, sets `mode: "midweek-reflow-{timestamp}"`.

## Files

- `~/.claude/notes/scratch/weekly-plan-{weekStart}.json` — final WEEK_DATA
- `~/.claude/notes/scratch/weekly-plan-draft-{weekStart}.json` — interim state, deleted on Phase 6 success
- `~/.claude/notes/scratch/quarterly-wins-{quarter}.json` — quarterly wins, read at Phase 1
- `~/.claude/notes/scratch/productive-client-map.json` — project-to-client lookup
- `~/.claude/skills/plan-week/references/interview-prompts.md` — question library, edit to iterate
- `~/.claude/skills/plan-week/references/week-data-schema.example.json` — example output
- `~/.claude/skills/plan-week/references/productive-client-map.example.json` — template

## Voice and Style

Peer in a hallway, not consultant in a deck. Direct, no preamble, no cheerleader sign-offs. No em dashes, no en dashes, no double-hyphens used as em dash substitutes. Use commas, periods, colons, parentheses instead.

Sample question style:
- "Zenith. What moves this week?"
- "Where in the week does the Cole reply land?"
- "Frame as written, or adjustments?"

## Hard Requirements (do not deviate)

- Phase 3 is THREADS-FIRST. Do not walk Sun → Sat asking "what's Tuesday." Walk client-by-client first.
- Every block, task, and delegation MUST carry a `client` field. This enables drift aggregation by client in future phases.
- Phase 4 questions are CONSOLIDATED. Do not ask row-by-row.
- Phase 5 final review is REQUIRED. Damon needs to see the full plan before write.
- Draft persistence after EVERY phase. Skill must be resumable.
- Default frame is APPLIED automatically, only confirms/adjusts. Do not ask Damon to specify the frame from scratch every Sunday.
- ALL questions to Damon MUST be numbered (1., 2., 3., ...). Even single questions. This applies across every phase, not just consolidated phases. Damon will reply by number.
