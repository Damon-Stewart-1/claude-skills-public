# /plan-week Interview Prompts

Question library for the /plan-week skill. Edit this file to iterate on the interview shape over time. Damon's voice: peer in a hallway, direct, no preamble.

No em dashes, no en dashes, no double-hyphens as em dash substitutes. Use commas, periods, colons, parentheses instead.

---

## Phase 1 — Pull context (no user-facing prompts)

Silent. No questions. Just pulls and reads.

If `productive.env.local` is missing:
> "Need a Productive API token for this session. Paste it here (won't be saved)."

If a Productive project name is not in the client map:
> "Productive project '{project_name}' isn't mapped yet. Which client?"

---

## Phase 2 — Surface patterns

No questions. Just observations. Sample print:

```
Last week (Apr 20):
- Threads with no movement: Pinx, ICSW
- Tasks carried forward: 4 incomplete (Zenith Cole reply, Dr. Adam phase 5, AND contract, Kamari entity)
- Quarterly wins (2026-Q2): "EI website live + 3 client wins announced"

Productive this week:
- Overdue: 6 tasks across 3 clients (Zenith, Earned Impact Internal, Synchrony)
- Due this week: 11 tasks across 5 clients

Heads up:
- May 15 is the Q3 planning trigger date. Three Sundays from now.
```

---

## Phase 3 — Threads-first interview

### Frame confirmation (single question, default applied)

> "Frame: Mon no external meetings except cofounders, Wed quiet, Fri hard stop noon, Sun 4hr quiet. Mornings 07-11 deep work. Email sweeps 11/15/16:30. Adjustments?"

Damon answers "no" or specifies overrides.

### Per-thread question

For each active client (Zenith, Dr. Adam, AND, Pinx, Kamari, Synchrony, ICSW, Earned Impact Internal, plus any new from Productive):

> "{Client}. What moves this week?"

Damon answers with a list. Each item gets a priority (P1, P2, P3, D).

If response is "nothing" or "skip", move on.

### Per-move placement question

After all threads gathered, for each move:

> "Where in the week does '{move}' land?"

Valid answers: day (Mon, Tue, Wed, Thu, Fri, Sat, Sun), time block (Mon 07-10), or "pool" (no specific day yet).

For longer items, can batch:
> "Placements for Zenith moves: 1) Cole reply, 2) GTM brief, 3) Jay sync. Day each, in order."

---

## Phase 4 — Consolidated questions

### Win conditions

> "Last week's win conditions:
>
> Client: {text}
> BizDev: {text}
> Team: {text}
>
> For each, carry, edit, or replace? Format: '{category}: {action} -> {new text if edit/replace}'."

Sample Damon response:
```
Client: carry
BizDev: replace -> "Cold email reconnected, 200 sends, 5 replies"
Team: edit -> "EI website finalized AND deployed"
```

### Delegations

> "Open delegations:
>
> Kaelene ({client}): {task} (status: {status}, last touched {date})
> Abigail ({client}): {task} (status: {status}, last touched {date})
> Fida ({client}): {task} (status: {status}, last touched {date})
>
> Status update on each in one response. Add new rows if needed."

Sample response:
```
Kaelene: Waiting -> Done (sent campaign Tue)
Abigail: Assigned -> Waiting on press kit images
Fida: no change
NEW: Sophia (Dr. Adam) -> draft message matrix by Thu
```

### Pushed-off

> "What's deferred this week? (one item per line, brief)"

Sample response:
```
EI Outbound Instantly campaign
ICSW Q2 review
Zenith TL competitive update
```

---

## Phase 5 — Final review

Print the full readable WEEK_DATA. Then:

> "Approve and write to weekly-plan-{weekStart}.json? (yes / edit / cancel)"

If "edit":
> "Which section? (win-conditions / threads / days / delegations / pushed-off)"

Then return to that phase's questions for that section only.

If "cancel":
> "Draft saved at weekly-plan-draft-{weekStart}.json. Exiting."

---

## Phase 6 — Write final (no user-facing prompts)

Silent write. Then print:

> "Written to ~/.claude/notes/scratch/weekly-plan-{weekStart}.json"

---

## Phase 7 — Quarter rollover

If trigger date passed and next-quarter wins not set:

> "Quarter {currentQuarter} ends in {N} weeks. Run /plan-quarter now or this Sunday's plan will hold a placeholder. Inject synthetic P1 task into next week pool? (yes / no)"

If yes, no further prompt. Just inject.

---

## Reflow mode (--reflow)

### Trigger question

> "Midweek reflow. What changed?"

Damon describes (e.g., "Cole crisis blew up Tuesday afternoon, lost 4 hours, need to push deep work").

### Then walk remaining days

> "Today is {day}. Reflowing {today} through Sun. Threads-first or jump to a specific day?"

If threads-first, run abbreviated Phase 3 (only ask about threads with movement remaining).

If jump, ask which day, then walk days from there.

### Final review identical to Sunday flow

Phase 5 prints, asks for approval, writes to same WEEK_DATA file with bumped version and `mode: midweek-reflow-{timestamp}`.

---

## Resume mode (--resume)

If draft exists:

> "Draft from Phase {N} exists for week of {weekStart}. Resuming from Phase {N+1}."

No further prompt. Continue from where draft left off.

---

## Restart mode (--restart)

If draft exists:

> "Draft for {weekStart} will be deleted. Confirm? (yes / no)"

If yes, delete draft, start Phase 1 fresh.
