# /pre-goal

Put the session into phase-by-phase task-and-goal mode. Run it once you have a plan and want each phase driven by a verifiable goal with a hard stop at every boundary.

## What it does

Turns each plan phase into a TodoWrite task, then works the plan one phase at a time. For each phase it emits a `/goal` block whose completion conditions are all transcript-verifiable (a file exists, a grep pattern matches, a command produced specific output, a build or test passed, a URL returned an expected status). Nothing that needs your judgment ever goes inside a goal, because the evaluator cannot verify a human sign-off and would loop the Stop hook.

When every condition is satisfied, Claude says "Phase N goal complete", lists the evidence for each condition, and stops. It does not start the next phase until you approve.

## Invoke

```
/pre-goal
```

No arguments needed. If a plan already exists in the session, Claude picks it up. If none exists, Claude asks (numbered) whether to plan first or define phase 1 from the task at hand.

## What to expect

Each approved phase boundary hands you the next phase's goal in two ways: always inline in a fenced code block, and, when a clipboard tool is available, copied to your clipboard as well (pbcopy on macOS, xclip or wl-copy on Linux). The inline block is the source of truth, so the skill still works on a machine with no clipboard tool.

## Constraints it enforces

- Every phase has a task and a goal whose conditions are 100% transcript-verifiable.
- No goal contains a human-judgment condition; sign-off lives at the phase boundary, outside the goal.
- The skill never advances past a phase boundary without your explicit approval. Plan approval is not phase approval.
- Goal strings and per-turn goal outputs stay under 4000 characters.

## Pairs well with

Run `/plan` first to produce the phased plan, then `/pre-goal` to execute it phase by phase with a goal on each phase.
