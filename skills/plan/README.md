# /plan

Interview-style planning skill. Run it at the start of any non-trivial task.

## What it does

Conducts a short binary-choice interview, then writes a phased implementation plan to `~/.claude/plans/`. Each phase has a verifiable completion promise: a bash command you can run to confirm the phase is actually done.

The goal is a plan a future Claude session can execute without you re-explaining anything.

## Invoke

```
/plan
```

No arguments needed. Claude will ask what you're building.

## What to expect

The interview is a mandatory gate. Claude asks five questions, one at a time, each as a simple lettered choice (1a/1b, 2a/2b), and you answer by letter:

1. Scope: a new thing, or a change to something existing
2. Done condition: how you will know it worked
3. Out of scope: anything related that should NOT be in this plan
4. Design reference: any visual or example to work from
5. Deploy target: where it ships

If a question is unclear, Claude asks a simpler version of the same one rather than moving on. After the interview, Claude confirms its understanding in a sentence or two, then writes the plan.

## Output

A markdown file at `~/.claude/plans/<contextual-name>.md` with:

- Frontmatter (status, created date)
- Problem statement and constraints
- Phases, each with: description, steps, and a completion promise
- Dispatch candidates flagged for background execution via `/dispatch`

## After the plan

Claude shows the phase outline, then the full plan, then runs an adversarial review before you approve. Three independent reviewers (a skeptic, a scope-cutter, and an implementation realist) each try to break the plan. Their objections are logged, and any rated HIGH must be resolved or explicitly waived before the plan is marked ready. This gate is automatic and runs on every plan.

## Setup

The skill reads a `gotchas.md` file from the skill directory to avoid known planning mistakes. That file is included. You can add your own project-specific gotchas as you accumulate them.

Plans output to `~/.claude/plans/`. That directory is created on first use.
