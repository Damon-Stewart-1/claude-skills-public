# Objection Outcomes Log

Tracks whether adversarial review objections turned out to be real problems during execution or noise. Used to self-tune reviewer prompts over time.

## Log Location

`~/.claude/plans/reviews/objection-outcomes.md`

Create this file the first time an outcome is tagged. It accumulates across all plans.

## Schema

| plan | objection (abbreviated to 60 chars) | reviewer | severity | outcome | notes |
|------|-------------------------------------|----------|----------|---------|-------|
| foo-plan | Phase 2 assumes bq auth is cached... | Realist | HIGH | real | Blocked Phase 2, needed re-auth |
| bar-plan | Self-tuning log is premature abstr... | Scope-Cutter | MED | noise | Built fine, no issues |

## Outcome Values

- `real` -- the objection predicted an actual problem that surfaced during execution
- `noise` -- execution completed without the objection mattering
- `partial` -- the objection pointed at a real area but the specific failure was different

## When to Tag

Tag during `/sync-context` at session end. Prompt:

> "Any review objections from this session worth tagging? Check `~/.claude/plans/reviews/{plan-name}.md` for HIGHs that were marked RESOLVED or WONTFIX."

Do not force tagging mid-session. Tag retrospectively.

## Self-Tuning Signal

When `real` count for a reviewer exceeds `noise` count by 2:1 over 5+ entries, that reviewer's prompt is well-calibrated.

When `noise` dominates for a specific category (e.g., Realist/implementation noise is consistently high), note it in `proposed_gotchas.md` for prompt tightening at next `/sync-context`.

Aggregate counts (update manually):

| reviewer | real | noise | partial | calibration |
|----------|------|-------|---------|-------------|
| Skeptic | 0 | 0 | 0 | uncalibrated |
| Scope-Cutter | 0 | 0 | 0 | uncalibrated |
| Realist | 0 | 0 | 0 | uncalibrated |
