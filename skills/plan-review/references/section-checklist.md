# Section-by-Section Review Checklist

Work through these in order. Spend time proportional to risk. Skip sections with nothing to say.

## 1. Architecture
- Is the structure right? Dependencies clean? Minimal new abstractions?
- Does it introduce coupling that will be painful to undo?
- Are the boundaries between components clear?

## 2. Error and Failure Modes
- Name every specific failure. What triggers it, what catches it, what the user sees.
- No generic "handle errors." Each failure mode needs: trigger condition, catch mechanism, user-visible result.
- Are there cascading failures that could take down adjacent systems?

## 3. Security and Threats
- Auth gaps, injection risks, data exposure, secrets handling
- Does this introduce new attack surface?
- Are secrets stored correctly (env vars, Keychain, not hardcoded)?

## 4. Data Flow and Edge Cases
- Trace happy path + three shadow paths: nil input, empty input, upstream error
- What happens when external services are down or slow?
- Are there data consistency risks (partial writes, stale reads)?

## 5. Performance
- N+1 queries, unnecessary work, scaling concerns
- What breaks at 10x current volume?
- Are there synchronous calls that should be async?

## 6. Observability
- Can you tell when this breaks in production? Logs, alerts, dashboards
- Are error messages actionable for oncall?
- Are the right metrics being tracked?

## 7. Deployment
- Partial states during rollout: what happens mid-deploy?
- Rollback plan: can you undo this cleanly?
- Migration path: does existing data need transformation?

## 8. Testing Strategy
- What must be tested, what test types, what can be deferred?
- Are the critical paths covered by automated tests?
- Are there integration points that need contract tests?

## For Each Finding

- State the issue clearly
- Rate severity: CRITICAL / WARNING / NOTE
- Provide a concrete fix or alternative
