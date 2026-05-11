# Team Templates

Three canonical team compositions, each with role definitions, model assignments, sequencing, expected wall time, and a copy-paste prompt skeleton. Pick the template that matches the task, then customize agent prompts for the specific question.

For all templates: capture the run-dir before spawning by running `bash "${CLAUDE_PLUGIN_ROOT}/skills/spawn-agent-team/scripts/setup-run-dir.sh" <task-slug>`. The script prints the absolute run-dir path on stdout. Substitute it everywhere `{RUN_DIR}` appears below.

## Template selection at a glance

| Template | Agents | Mix | Use when | Wall time |
|---|---|---|---|---|
| A (3/3/3/1) | 10 | 3 Sonnet research, 3 Haiku counter, 3 contrarian (2 Gemini + 1 Sonnet), 1 Sonnet aggregator | Complex research, multiple defensible answers, want adversarial pressure | 5-7 min |
| B (2/2/1) | 5 | 2 Sonnet research, 2 Gemini contrarian, 1 Sonnet aggregator | Narrow questions, quick triage, 2 hypotheses to test | 2-3 min |
| C (4/4+1+1) | 10 | 4 Sonnet finder, 4 Haiku arguer, 1 Gemini contrarian, 1 Sonnet aggregator | Max-confidence decision, want input variance surfaced | 5-7 min |

Template C uses 1 Gemini because its 4-Sonnet, 4-Haiku core is doing the heavy lift and the contrarian is a tiebreaker. If the task is SEO or content positioning, switch to Template B with both contrarians as Gemini, or modify Template C to swap one Sonnet finder for a Gemini.

---

## Template A: 3/3/3/1 (research, counter, contrarian, aggregator)

### When to use

The question has multiple defensible answers and the failure mode you want to guard against is "lead picks the first plausible answer without pressure-testing it." Three independent research lines, three counter-arguments against each, three independent contrarian picks, one aggregator to synthesize.

### Composition

- **3 Sonnet researchers.** Each takes the same task brief but produces an independent answer. Different framings emerge naturally.
- **3 Haiku counter-arguers.** Each reads one researcher's output and argues why that researcher is wrong. Counters spawn in Wave 2 because they need the researcher output as input.
- **3 contrarians: 2 Gemini, 1 Sonnet.** Each produces an independent pick with no input from the researchers. Contrarians spawn in Wave 1 alongside the researchers (independent by design).
- **1 Sonnet aggregator.** Reads all 9 prior outputs in Wave 2, produces a ranked synthesis with confidence levels.

Total: 10 agents. Gemini ratio: 2/10.

### Sequencing

- **Wave 1 (parallel):** 3 researchers + 3 contrarians = 6 agents.
- **Wave 2 (after Wave 1 returns):** 3 counter-arguers (each gets one researcher's output) + 1 aggregator = 4 agents.

Wave 2 spawns once all Wave 1 outputs are written.

### Prompt skeletons

**Researcher (Sonnet, x3):**
```
Role: researcher-{N}.
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Read every input file in full before answering. Produce an independent answer with reasoning. Do not coordinate with other researchers.
Write your output to: {RUN_DIR}/researchers/researcher-{N}.md
Return when done.
```

**Counter-arguer (Haiku, x3):**
```
Role: counter-{N}.
Task: Read {RUN_DIR}/researchers/researcher-{N}.md and argue why it is wrong. Find the strongest case against its conclusion. Propose what you think is the correct answer instead.
Be specific. Quote the researcher's claim, then refute it.
Write your output to: {RUN_DIR}/counters/counter-{N}.md
Return when done.
```

**Contrarian (2 Gemini + 1 Sonnet):**
```
Role: contrarian-{N}.
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Read every input file in full. Produce an independent answer. Do not consult any researcher output. Your job is to surface answers the research line might miss.
Write your output to: {RUN_DIR}/contrarians/contrarian-{N}.md
Return when done.
```

**Aggregator (Sonnet, x1):**
```
Role: aggregator.
Task: Read all 9 outputs in {RUN_DIR}/researchers/, {RUN_DIR}/counters/, {RUN_DIR}/contrarians/.
Produce a synthesis with: vote tally, ranked findings with confidence (HIGH/MEDIUM/LOW), areas of agreement, areas of disagreement, your recommendation.
Quote at least one direct sentence from each agent in your synthesis as proof you read the files.
Write your output to: {RUN_DIR}/aggregator/SYNTHESIS-draft.md
Return when done.
```

The aggregator's output is a draft; the lead reads all raw outputs plus the aggregator draft, then writes the final `{RUN_DIR}/SYNTHESIS.md`.

---

## Template B: 2/2/1 (small team, fast)

### When to use

The question is narrow. Two research framings cover it. You want fast wall time and a clean Gemini ratio (40%) for content or independent perspective. Triage decisions, "should we use library X or Y", quick competitive checks.

### Composition

- **2 Sonnet researchers.** Each takes one framing or one hypothesis.
- **2 Gemini contrarians.** Each produces an independent pick with no Sonnet input. 40% Gemini ratio meets the SEO/content bar cleanly.
- **1 Sonnet aggregator.** Synthesizes the 4 prior outputs.

Total: 5 agents. Gemini ratio: 2/5 (40%).

### Sequencing

- **Wave 1 (parallel):** 2 researchers + 2 contrarians = 4 agents.
- **Wave 2:** 1 aggregator.

### Prompt skeletons

**Researcher (Sonnet, x2):**
```
Role: researcher-{N}.
Framing: {YOUR_FRAMING}. (Researcher 1 takes framing A, Researcher 2 takes framing B.)
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Read every input file in full. Produce an answer assuming your framing. Do not coordinate.
Write your output to: {RUN_DIR}/researchers/researcher-{N}.md
Return when done.
```

**Contrarian (Gemini, x2):**
```
Role: contrarian-{N}.
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Independent pick. Do not consult researcher output. Write what you think is right.
Write your output to: {RUN_DIR}/contrarians/contrarian-{N}.md
Return when done.
```

**Aggregator (Sonnet, x1):**
```
Role: aggregator.
Read {RUN_DIR}/researchers/* and {RUN_DIR}/contrarians/*. Produce a ranked synthesis with confidence levels and a recommendation. Quote at least one sentence from each agent.
Write your output to: {RUN_DIR}/aggregator/SYNTHESIS-draft.md
Return when done.
```

---

## Template C: 4/4+1+1 (the proven test pattern)

### When to use

Max-confidence decision where input variance is the point. Four independent finders, four adversarial arguers, one Gemini for outside-the-room perspective, one aggregator. This is the pattern that ran clean on the 4 finder + 4 arguer + 1 Gemini + 1 aggregator test. Use it when the cost of getting the answer wrong is high.

### Composition

- **4 Sonnet finders.** Each independently produces an answer to the same question. Variance across finders surfaces blind spots.
- **4 Haiku arguers.** Each takes one finder's output and argues against it. The arguers can also propose alternatives.
- **1 Gemini contrarian.** One independent outside pick.
- **1 Sonnet aggregator.** Synthesizes all 9 prior outputs.

Total: 10 agents. Gemini ratio: 1/10.

This template under-provisions Gemini relative to the 5+ agent floor. That is intentional for code or system-architecture tasks where the Sonnet/Haiku core carries the load. For SEO or content tasks, swap one Sonnet finder for a Gemini, raising the ratio to 2/10.

### Sequencing

- **Wave 1 (parallel):** 4 finders + 1 contrarian = 5 agents.
- **Wave 2 (after Wave 1 returns):** 4 arguers (each gets one finder's output) + 1 aggregator = 5 agents.

### Prompt skeletons

**Finder (Sonnet, x4):**
```
Role: finder-{N}.
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Read every input file in full. Produce an independent answer. Do not coordinate with other finders.
Write your output to: {RUN_DIR}/finders/finder-{N}.md
Return when done.
```

**Arguer (Haiku, x4):**
```
Role: arguer-{N}.
Task: Read {RUN_DIR}/finders/finder-{N}.md and argue why it is wrong. Propose what you think is right.
Be specific. Quote, refute, replace.
Write your output to: {RUN_DIR}/arguers/arguer-{N}.md
Return when done.
```

**Contrarian (Gemini, x1):**
```
Role: contrarian.
Task: {TASK_BRIEF}.
Input files: {INPUT_PATHS}.
Independent outside pick. Do not consult finder or arguer output.
Write your output to: {RUN_DIR}/contrarians/contrarian-1.md
Return when done.
```

**Aggregator (Sonnet, x1):**
```
Role: aggregator.
Read all 9 outputs in {RUN_DIR}/finders/, {RUN_DIR}/arguers/, {RUN_DIR}/contrarians/.
Produce a vote tally, ranked top picks with confidence, areas of split, recommendation. Quote at least one sentence from each agent.
Write your output to: {RUN_DIR}/aggregator/SYNTHESIS-draft.md
Return when done.
```

---

## Customizing or designing a custom team

If none of the three templates fit:

1. State the task and the answer shape (ranked list, single pick, comparison matrix, etc.).
2. Pick a primary research role (3-4 agents). Sonnet for general research, Haiku if fast and parallel, Gemini if independent perspective is the point.
3. Decide if you need adversarial pressure. If yes, add a counter or arguer role (Haiku is the default).
4. Always include at least one contrarian (Gemini for content, Sonnet for code-heavy tasks).
5. Include an aggregator if the team is 5+ agents.
6. Verify Gemini ratio: 2 minimum for teams of 5+, 1 acceptable for teams under 5, 40%+ for SEO/content.
7. Check team total against max 10. If you exceed it, run multiple rounds.

Document the custom mix at the top of SYNTHESIS.md so the run is reproducible.
