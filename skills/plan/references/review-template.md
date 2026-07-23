# Review File Template

Reviews are saved to `~/.claude/plans/reviews/{plan-name}.md` immediately after adversarial dispatch completes.

## File Structure

```markdown
---
plan: {plan-name}
reviewed: {ISO timestamp}
status: BLOCKED | READY
high_unresolved: {count}
---

# Adversarial Review: {plan title}

## Skeptic

{one objection per line: [HIGH|MED|LOW] [category] text}

## Scope-Cutter

{one objection per line: [HIGH|MED|LOW] [category] text}

## Implementation Realist

{one objection per line: [HIGH|MED|LOW] [category] text}

---

## Readiness Gate

To resolve a HIGH objection, either:
- Add a written response inline in the plan file at the relevant phase, then mark it here: `[HIGH] [category] <text> -- RESOLVED: <one-line summary>`
- Tag it here: `[HIGH] [category] <text> -- WONTFIX: <reason>`

Status is READY when this command returns 0:
`grep -c '^\[HIGH\]' ~/.claude/plans/reviews/{plan-name}.md | grep -v 'RESOLVED\|WONTFIX'`

(Exact verification command is written into the file at review time with the real plan name substituted.)
```

## Severity Definitions

| Severity | Meaning |
|----------|---------|
| HIGH | Unaddressed, this causes plan failure or wrong outcome. Must be resolved or WONTFIX before status = READY. |
| MED | Creates rework or delay. Logged for reference, does not block. |
| LOW | Edge case or noise. Logged, ignored unless pattern repeats. |

## Closing Objections

Append one of these suffixes to the objection line (space-separated, same line):

- `-- RESOLVED: <one-line summary of what changed in the plan>`
- `-- WONTFIX: <reason this is acceptable to leave open>`

Do not delete objection lines. The log is append-only.

## Category Definitions

| Category | Meaning |
|----------|---------|
| assumption | A belief about the world that may not be true |
| scope | Something included that probably should not be, or excluded that probably should be |
| implementation | A concrete execution obstacle: missing tool, wrong command, permission block, API gap |
