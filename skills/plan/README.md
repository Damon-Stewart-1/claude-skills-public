# /plan

Interview-style planning skill. Run it at the start of any non-trivial task.

## What it does

Conducts a structured interview (2-3 rounds), then writes a phased implementation plan to `~/.claude/plans/`. Each phase has a verifiable completion promise -- a bash command you can run to confirm the phase is actually done.

The goal is a plan a future Claude session can execute without you re-explaining anything.

## Invoke

```
/plan
```

No arguments needed. Claude will ask what you're building.

## What to expect

**Round 1** covers the problem, what already exists, and constraints you wouldn't guess from context.

**Round 2** pins down the done condition and what's explicitly out of scope.

**Round 3** (only if needed) clears up integration points or unresolved scope.

After the interview, Claude confirms its understanding, then writes the plan. You review the phase outline before the full plan is written.

## Output

A markdown file at `~/.claude/plans/<generated-name>.md` with:

- Frontmatter (status, created date)
- Problem statement
- Phases, each with: description, steps, and a completion promise
- Dispatch candidates flagged for background execution via `/dispatch`

## After the plan

Once approved, Claude will offer to dispatch reviews via `/plan-review`. Worth doing for anything with more than 3 phases or external dependencies.

## Setup

The skill reads a `gotchas.md` file from the skill directory to avoid known planning mistakes. That file is included. You can add your own project-specific gotchas as you accumulate them.

Plans output to `~/.claude/plans/`. That directory is created on first use.
