# Ralph Wiggum Quick Reference

## Safe Defaults
```bash
/ralph-loop "task" --max-iterations 15 --completion-promise "DONE"
```

## Iteration Limits by Task Type
| Task | Max Iterations |
|------|----------------|
| Typo/simple fix | 5 |
| Bug fix | 10 |
| Small feature | 15 |
| Medium feature | 25 |
| Large refactor | 40 |

## When to Use Ralph
- Tasks with clear "done" criteria
- Getting tests to pass
- Building features with defined requirements
- Refactoring with test coverage

## When NOT to Use Ralph
- Vague goals ("make it better")
- Tasks needing human judgment
- Production systems
- Anything without clear success criteria

## Emergency Stop
```bash
/cancel-ralph
```
Or press `Ctrl+C` twice.

## Preferred Commands

### /safe-ralph
Preferred alias over `/ralph-loop`. Auto-enforces safeguards: validates max-iterations is set, checks for completion-promise, and warns before destructive operations.

```bash
/safe-ralph "task description" --max-iterations 15
```

Use this instead of `/ralph-loop` for all new loops.

### /ralph-preflight
Run before any long autonomous session. Checks:
- Session context is not already near limit
- Target files are not locked or actively edited
- Completion criteria are clear and testable
- No production systems are in scope
- Iteration limit is appropriate for task complexity

```bash
/ralph-preflight
```
Then confirm before starting the loop.
