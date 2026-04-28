---
name: leadership-plan-daily
description: Morning daily planning interview. Reads the current week's WEEK_DATA, surfaces today's scheduled blocks, then walks through priorities and time-blocking conversationally. Triggers on "/leadership-plan-daily", "plan my day", "daily planning", "morning planning", "time block today". Lightweight complement to /leadership-plan-week.
user_invocable: true
---

# /leadership-plan-daily -- Daily Planning Interview

Quick morning interview, target under 10 minutes. Conversational, iterative. One question at a time.

## Modes

```
/leadership-plan-daily            # Default: plan today
/leadership-plan-daily --tomorrow # Plan tomorrow (useful end-of-day)
/leadership-plan-daily --reflow   # Mid-day reflow after disruption
```

## Default Mode: Step-by-Step

### Step 1 -- Load context (silent)

Compute `today` (ISO date + day-of-week label) and `weekStart` (most recent Sunday).

Read `~/.claude/notes/scratch/weekly-plan-{weekStart}.json`. If not found, print:
"No week plan found for week of {weekStart}. Run /leadership-plan-week first, or continue without it? (1. run it now / 2. continue without)"

Read `~/.claude/notes/scratch/daily-plan-{today}.json` if it exists. If found, print:
"A daily plan for {today} already exists (last updated {time}). (1. resume / 2. restart)"

Read `~/.claude/notes/scratch/daily-plan-{yesterday}.json` if it exists. Extract any blocks
where `done` is not `true` (or where `done` is absent). These are unfinished items from
yesterday. Store them as `carriedFromYesterday` array. Do not auto-schedule them. Do not
auto-move them. Just hold them for display in Step 2.

### Step 2 -- Print today's context (read-only, no question yet)

Show what's already on the books from WEEK_DATA, plus anything carried from yesterday.
No question. Just surface it.

```
TODAY: {DAY} {date}
{tag if present: QUIET DAY / NO EXTERNAL MEETINGS / HALF DAY}

SCHEDULED BLOCKS
{time}  {label} ({client})
        {notes if present}
...

CARRIED FROM YESTERDAY ({count} unfinished)
  {label} ({client})
  ...
```

If there are no carried items, omit that section entirely.
If WEEK_DATA has no blocks for today, print: "No blocks scheduled from your week plan."

### Step 3 -- Most important thing

Ask one question:

> "1. What's the one most important thing you need to accomplish today?"

Wait for response. Capture it as Priority 1.

If Damon says "same as planned" or "nothing new": accept it, use the top block from WEEK_DATA as Priority 1, move to Step 4.

### Step 4 -- Three priorities

Ask:

> "2. What are your 3 priorities today? (not more than 3)"

Wait for response. Capture as Priority 1, 2, 3. If Damon already gave Priority 1 in Step 3, confirm it and ask for 2 and 3.

If Damon says "just the one" or "nothing else": accept it and move to Step 5 with whatever was given.

### Step 5 -- Time-block each priority, one at a time

For each priority in order, ask one question:

> "3. Where in the day does [{priority 1 label}] land?"

Wait. Capture the time slot. Then:

> "4. Where does [{priority 2 label}] land?"

And so on. One at a time. Do not bundle them.

If Damon says "open slot" or "whenever": record it as unscheduled and move on.

### Step 6 -- EI outbound question (never skip)

This question is asked every single day, without exception, even if Damon seems done:

> "5. What's one move today that advances EI outbound?"

Wait for response. Capture it as a task with client: "Earned Impact".

If Damon says "nothing" or "not today": accept it and move on. Do not push.

### Step 7 -- Show the locked plan and ask for approval

Print the full day plan:

```
LOCKED: {DAY} {date}

{time}  {label} ({client})
        {notes}
...

UNSCHEDULED TASKS
{label} ({client})
...
```

Ask:

> "6. Approve and save? (1. yes / 2. edit)"

If edit: ask which item to change, apply it, re-show the plan, ask again.
If yes: proceed to Step 8.

### Step 8 -- Write and close

Write `~/.claude/notes/scratch/daily-plan-{today}.json`:

```json
{
  "date": "YYYY-MM-DD",
  "dayLabel": "MON Apr 28",
  "weekStart": "YYYY-MM-DD",
  "createdAt": "ISO timestamp",
  "version": 1,
  "blocks": [
    {
      "time": "9:00 AM",
      "label": "string",
      "client": "string",
      "priority": 1,
      "notes": "string",
      "done": false
    }
  ],
  "unscheduled": [
    {
      "label": "string",
      "client": "string",
      "done": false
    }
  ],
  "carriedFromYesterday": [
    {
      "label": "string",
      "client": "string",
      "originalDate": "YYYY-MM-DD"
    }
  ],
  "outboundMove": "string or null",
  "notes": "string"
}
```

Print: "Locked. Daily plan written to ~/.claude/notes/scratch/daily-plan-{today}.json"

Stop. No further output.

## Reflow Mode (--reflow)

Invoked mid-day when something disrupted the plan.

Read `daily-plan-{today}.json`. If not found, print: "No daily plan found for today. Run /leadership-plan-daily first."

Ask one question:

> "1. What changed? What's left?"

Capture the answer. Reflow only the remaining time slots. Do not re-litigate the morning.

Write the updated file, bump `version`, add `reflowAt: ISO timestamp`.

Print: "Reflowed. Remaining day updated."

Stop.

## Tomorrow Mode (--tomorrow)

Same as default but targets tomorrow's date and tomorrow's blocks from WEEK_DATA.

Writes `daily-plan-{tomorrow}.json`.

## Hard Requirements

- One question at a time. No multi-part dumps. Wait for the answer before moving forward.
- If Damon says "nothing," "same as planned," or "looks good" at any point: accept it and move on. Do not push.
- Step 6 (EI outbound) is asked every single day. It is never skipped, never optional.
- All questions must be numbered (1., 2., 3., ...).
- No em dashes, no en dashes, no double-hyphens as em dash substitutes.
- Every block and task must carry a `client` field.
- Write only to `~/.claude/notes/scratch/`. Never touch WEEK_DATA directly.
- Step 2 is read-only. No question until Step 3.
