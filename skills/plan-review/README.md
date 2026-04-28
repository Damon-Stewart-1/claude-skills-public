# /plan-review

Adversarial plan review. Challenges premises, finds failure modes, surfaces alternatives before you build anything.

Adapted from [garrytan/gstack](https://github.com/garrytan/gstack).

## What it does

Reviews a plan file and returns a structured verdict: APPROVE, APPROVE_WITH_CHANGES, RETHINK, or BLOCKED. Every finding is rated CRITICAL, WARNING, or NOTE. Every finding has a concrete fix, not a vague suggestion.

The review covers: premise validity, whether this is the right problem, implementation alternatives, how the plan moves toward or away from the 12-month ideal state, and a section-by-section checklist.

## Invoke

```
/plan-review
```

Or pass a file path and mode directly:

```
/plan-review ~/.claude/plans/my-plan.md --mode selective
```

## Modes

| Mode | Use when |
|------|----------|
| `expand` | Brainstorming, want to see what's possible |
| `selective` | New plan, want scope held but expansion opportunities surfaced |
| `hold` | Scope is locked, just make it bulletproof |
| `reduce` | Plan is too big, find the minimum viable version |

Claude auto-suggests a mode based on the plan. You confirm before it runs.

## How I use it: adversarial + collegial in parallel

The most useful pattern is two reviews at once, from different postures:

**Adversarial (Gemini):** Dispatch to Gemini via `/dispatch` with `--mode hold` or `--mode selective`. Gemini tends to find infrastructure edge cases and data flow problems that Claude misses. Good for: plans touching external APIs, database schemas, auth flows, anything with real failure cost.

**Collegial (Sonnet):** Dispatch a second review with Sonnet using `--mode selective`. Sonnet reads more like a thoughtful colleague -- it'll flag scope creep and sequencing issues without trying to tear the whole thing down.

Read both outputs before touching an implementation file. If they agree on a CRITICAL, it's a real blocker. If only one flags something, use your judgment. The point isn't consensus, it's coverage.

You can run both from `/plan` after the plan is written -- it will ask which reviewers to dispatch.

## Output

A review file at `~/.claude/jobs/<job-id>.md` (if dispatched) or inline in the current session.

Structure:
```
VERDICT: [APPROVE / APPROVE_WITH_CHANGES / RETHINK / BLOCKED]

CRITICAL issues: N
WARNING issues: N
NOTE issues: N

Top 3 action items:
1. ...
2. ...
3. ...

Deferred concerns:
- ...
```
