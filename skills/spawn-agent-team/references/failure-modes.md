# Failure Modes

Every case below has an explicit recovery action and a rule for when to escalate to the user. The principle: report back honestly, never pretend, never silently retry more than once.

## Quick lookup

| Failure | Recovery | Escalate? |
|---|---|---|
| Single agent crash | Spawn 1 reserve, same model class | No (unless reserve also fails) |
| Single agent empty output | Treat as crash, spawn 1 reserve | No (unless reserve also fails) |
| All agents in a role crash | Stop, ask the user | Yes |
| Aggregator crash | Lead synthesizes from raw outputs, mark "lead-only" | Note in synthesis |
| All Geminis crash (rate limit) | Stop, ask if Sonnet substitution is OK | Yes |
| File write failure | Detect empty output dir, treat as crash | Yes if pattern repeats |
| Timeout (>10 min, no return) | Treat as crash, spawn 1 reserve | No (unless reserve also fails) |
| Reserve also fails | Stop, do not loop, escalate | Yes |
| Partial team success | Synthesize on what returned, note what is missing | No |

## Detailed cases

### Single agent crash

**Symptom:** One agent's Agent tool call returns an error, exits before writing output, or returns a notification with a failure flag.

**Recovery:** Spawn one reserve agent. The reserve uses the same prompt and the same model as the primary. The reserve writes to the same file path the primary would have written to (e.g., `{RUN_DIR}/researchers/researcher-2.md` if researcher-2 failed).

**Do not:** Loop. Spawn at most one reserve per primary. If the reserve also fails, escalate.

**Tell the user:** Brief mention at the start of synthesis. "Researcher 2 crashed; reserve completed successfully." Do not bury this.

### Single agent empty output

**Symptom:** Agent returned without error but its output file is empty or contains only a stub. This usually means: the agent could not write to the path, the agent misread the brief, or the agent silently capitulated.

**Recovery:** Treat as a crash. Spawn one reserve. Before spawning, verify the run-dir is writable (`bash setup-run-dir.sh` should have created it; if not, fix the dir before retrying).

**Tell the user:** Note that the primary returned empty, what the reserve produced, and any guess at why the empty output happened.

### All agents in a role crash

**Symptom:** All 3 researchers crash, all 4 arguers crash, etc. This is usually a model-side issue (rate limit, model outage) or a bug in the role's prompt template.

**Recovery:** Stop spawning reserves. Print to the user:

```
spawn-agent-team: all {N} {role} agents failed.

Errors observed: {error summary}.

Options:
1. Retry with the same model class
2. Swap to a different model class (e.g., Haiku for Sonnet)
3. Proceed without this role and synthesize on what returned
4. Abort the run

Reply with the option number.
```

**Do not:** Silently retry, silently substitute models, or pretend the role completed.

### Aggregator crash

**Symptom:** All other agents returned but the aggregator failed.

**Recovery:** The lead synthesizes directly from the raw agent outputs. Read every `{role}/{agent-N}.md` file in full, produce SYNTHESIS.md with the same structure the aggregator would have produced.

**Mark the synthesis "lead-only".** At the top of SYNTHESIS.md add: `Note: aggregator agent crashed. Synthesis produced by lead instance from raw outputs without aggregator pre-pass.`

**Tell the user:** This is not a fatal failure. The lead can do the job. But it is worth noting because aggregator quality typically exceeds lead-only synthesis on 5+ agent runs.

### All Geminis crash (rate limit or API issue)

**Symptom:** Every Gemini contrarian returns an error or the gemini subagent reports a Google API failure.

**Recovery:** Stop. Ask the user:

```
spawn-agent-team: all {N} Gemini contrarians failed (likely Google API rate limit or outage).

Options:
1. Retry Gemini in 2 minutes
2. Substitute Sonnet contrarians (loses independent-from-Anthropic perspective)
3. Substitute Haiku contrarians
4. Proceed without contrarians (synthesis runs on primary research only)
5. Abort the run

Reply with the option number.
```

**Why ask:** The Gemini ratio is load-bearing for some tasks (SEO, content). Substituting Sonnet defeats the point. The user's call.

### File write failure (agent tried to write to ~/.claude/)

**Symptom:** Agent returned successfully but its output file does not exist. This usually means the agent tried to write to `~/.claude/` (sensitive path, blocked even with bypassPermissions).

**Recovery:** This should be impossible if the agent prompt used the run-dir path correctly. If it happens:

1. Verify the agent's prompt actually contained the run-dir path (not `~/.claude/...`).
2. If the prompt was correct, the agent disobeyed; spawn one reserve with the same prompt and a stronger directive: `WRITE ONLY TO {RUN_DIR}/...`. Do not let it pick its own path.
3. If the prompt had `~/.claude/` in it, fix the spawn code in the lead's call and retry.

**Escalate** if this happens twice in the same run; it indicates a bug in the spawn pattern.

### Timeout (agent runs >10 min without output)

**Symptom:** Agent has been running for over 10 minutes and has not returned. The Agent tool may not enforce a timeout; the lead has to.

**Recovery:** Treat as a crash. Cancel the call if possible, spawn one reserve.

**Note:** This is rare. Sonnet research agents typically return in 30-90 seconds. Haiku argue agents return in 15-60 seconds. Gemini contrarians return in 60-180 seconds depending on Google API load. A 10+ minute timeout usually indicates a stuck tool call inside the agent.

**Tell the user:** Note the timeout, the role, and any partial output observed.

### Reserve also fails

**Symptom:** A primary failed, a reserve was spawned, the reserve also failed.

**Recovery:** Stop. Do not spawn a second reserve. Escalate to the user:

```
spawn-agent-team: {role} primary and reserve both failed.

Options:
1. Try a different model for this role (e.g., Sonnet if both Haikus failed)
2. Proceed without this role
3. Abort the run

Reply with the option number.
```

**Why hard cap at 1 reserve:** If two agents on the same prompt both fail, the prompt or the model class is the issue. A third try will not help; it just wastes wall time and burns context.

### Partial team success (some succeed, some don't)

**Symptom:** Mixed outcome. 3 of 4 finders returned, 1 finder and 2 arguers crashed (with reserves also failing or not yet attempted).

**Recovery:** Proceed immediately with synthesis on the agents that succeeded. Do not halt the whole run waiting for permission unless an entire role is gone.

**At the top of SYNTHESIS.md:**
- List the agents that returned successfully.
- List the agents that failed and were not recovered.
- Note any role where the team is fully missing (e.g., "all 3 contrarians failed; synthesis is research-only").

**Tell the user:** Concise summary in the report. The user can decide whether to re-run the failed role or accept the partial synthesis.

## Anti-patterns to avoid

- **Silent retry.** Spawning a third or fourth attempt without telling the user. Wastes wall time, hides the underlying issue.
- **Silent model substitution.** Swapping Haiku for Sonnet because Haiku failed, without asking. Defeats the model routing rule.
- **Pretending an empty output is valid.** If an agent returns nothing, the run has lost data. Treat it as a failure, not as "the agent had nothing to add."
- **Synthesizing without reading.** If an agent crashed, do not include it in the vote tally as if it had returned.
- **Cascading reserves.** Reserve fails, spawn another reserve, that one fails, spawn another. Hard cap at 1 reserve per primary.
- **Hiding failures in the synthesis.** If 2 of 4 finders failed, say so at the top of SYNTHESIS.md. The user needs to know the synthesis is partial.
