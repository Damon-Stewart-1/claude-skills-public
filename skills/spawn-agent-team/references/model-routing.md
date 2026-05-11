# Model Routing

Decision tree for which model goes on which agent. Default to the cheapest model that can do the job. Opus is gated.

## Mechanism: how to actually pass a model

Model assignment is set via the `model` parameter on the Agent tool call. Prose like "use sonnet" inside the agent's prompt does not change which model runs.

For Anthropic models (Sonnet, Haiku, Opus): set `model: "sonnet"`, `model: "haiku"`, or `model: "opus"` on the Agent tool call.

For Gemini: route through the `gemini` subagent (`subagent_type: gemini`). The gemini subagent calls Google's API. The user is on a generous free tier as of 2026-05.

## Decision tree by role

### Sonnet (default for)

- **Research.** Multi-document synthesis, finding patterns across files, building an argument. Sonnet handles long context and multi-step reasoning.
- **Synthesis and aggregation.** The aggregator role almost always runs Sonnet. It reads 5-9 prior outputs and produces a structured ranking.
- **Multi-step reasoning.** Anything that requires holding several constraints in mind at once.
- **Anything that benefits from longer context.** Code review across many files, plan analysis, content with multiple sources.

### Haiku (default for)

- **Adversarial argue.** Counter-arguers and arguers in Templates A and C. The job is "read one document, find the strongest case against it." Haiku is fast and adequate for single-document refutation.
- **Single-document review.** Spot-checks, fact-checks, formatting passes.
- **Fast and parallel-friendly.** When you want 4 agents to return in 90 seconds rather than 3 minutes.

Haiku is not adequate for: multi-document synthesis, ranked aggregation, anything requiring long-form reasoning. If the role requires reading more than one document and producing a structured output, default to Sonnet.

### Gemini (default for)

- **Contrarian role.** Independent perspective with no Anthropic-model priors. The whole point of contrarians is to surface answers the Sonnet/Haiku research line might miss. Gemini's training and posture differ enough to be useful here.
- **Independent verification.** When the question is "are we missing anything obvious?", Gemini's view is the cleanest available second opinion.
- **SEO and content research.** Gemini's training corpus and Google integration make it stronger on web content patterns and SEO-adjacent reasoning. Raise the Gemini ratio to 40%+ for these tasks.
- **Domain-specific knowledge gaps.** When the question touches a domain Anthropic models are weaker on (some legal, some medical, some non-Western context), test Gemini.

Gemini is not the default for: code generation in the active codebase (Sonnet has more context on the running session), tasks where consistency with prior Anthropic outputs matters, or anything requiring tight tool integration (Read, Write, Edit) within Claude Code's harness.

### Opus (NEVER default)

Opus is gated. Two paths to use it:

1. **Explicit user ask.** "Use Opus for this." Then assign Opus.
2. **Lead surfaces a numbered question first.** If the lead judges Opus is needed, ask before spawning. See template below.

The reason: Opus is the most expensive model and the user is on a Max plan where heavy use compounds. The lead's judgment that "this needs Opus" should be checkable. Most tasks the team handles do not need Opus; Sonnet is the right tool 90% of the time.

#### Opus surfacing question template

When the lead thinks Opus is needed, print this format and wait:

```
Considering Opus for the {role} agent because {specific reason}.

Confirm or override:
1. Use Opus
2. Stick with Sonnet
3. Use Sonnet first, escalate to Opus only if it fails
```

The "specific reason" must be concrete. Examples that pass the bar:
- "This involves multi-document architectural reasoning across 8+ files where Sonnet has historically missed edge cases on the issue tracker codebase."
- "The aggregator is reconciling conflicting outputs from 9 agents across 3 framings; the synthesis quality matters because this is a go/no-go decision."
- "The contrarian needs to refute a 4-agent consensus and produce a defensible alternative; this is where Sonnet typically capitulates."

Examples that do NOT pass the bar:
- "Just to be safe."
- "This is important."
- "The user might want it."

If the reason is not concrete, default to Sonnet.

## Reserve agents

Reserves spawn when a primary fails (see `failure-modes.md` for the full table). The rule:

**Reserves match the model of the primary they replace.** A failed Sonnet researcher gets a Sonnet reserve. A failed Haiku arguer gets a Haiku reserve. A failed Gemini contrarian gets a Gemini reserve.

**Reserves do not chain.** If a reserve also fails, escalate to Damon. Do not spawn a reserve for a reserve. The hard cap is one reserve per primary.

**Reserves use the same prompt as the primary.** Do not modify the brief. The point of the reserve is to retry the same task with a fresh agent context, not to redesign the role.

## Cost discipline (informational)

The user is on the Max plan: Anthropic models do not bill per-token at the user level. Gemini calls go through Google's API on a generous free tier. So cost is not the binding constraint.

The binding constraints are wall time and synthesis quality:

- A 10-agent team takes 5-7 minutes wall time.
- A bad synthesis from a wrong-model assignment is more expensive than a fast wrong synthesis, because the lead has to re-spawn.
- Default to the cheapest model that can do the job because it returns faster, not because it costs less.

## Quick lookup table

| Role | Default model | Rationale |
|---|---|---|
| Researcher / Finder | Sonnet | Multi-document, multi-step |
| Counter-arguer / Arguer | Haiku | Single-document refutation, fast |
| Contrarian (general) | Gemini for 1, Sonnet for additional | Independent perspective |
| Contrarian (SEO/content) | Gemini | Domain strength |
| Aggregator | Sonnet | Reads 5-9 outputs, ranks |
| Reserve | Match primary | Same task, fresh context |
| Anything Damon explicitly asks | Whatever Damon said | Override |
