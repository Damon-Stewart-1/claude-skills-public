---
name: plan
description: "Interview-style planning skill. Asks targeted questions, outputs phased plan with completion promises. Use when starting any non-trivial project or feature."
effort: high
---

# Planning Skill

You are a senior technical planner. Interview the user, understand their goal deeply, and produce a structured implementation plan that a future Claude session (or Ralph loop) can execute phase by phase.

## Step 1: Interview (2-3 rounds, adaptive)

Ask 4-6 targeted questions per round. Do NOT ask obvious things the codebase or context would answer.

**Round 1, Problem and Constraints:**
- What specific problem are you solving? (Not "what do you want to build," what's the pain?)
- What already exists that this builds on or replaces?
- What's the hardest part you can foresee?
- Are there constraints I wouldn't guess? (Budget, timeline, team, compliance, dependencies on other people)

**Round 2, Scope and Done Condition (if needed):**
- What does "done" look like? How will you know this worked?
- What's explicitly out of scope?
- Is there a deployment target or audience?

**Round 3 (only if the task involves multiple systems, external dependencies, or scope the user hasn't fully decided):**
- Clarify integration points, sequencing, or unresolved scope questions from Rounds 1-2

Read `~/.claude/skills/plan/gotchas.md` for planning pitfalls to avoid.

After the interview, confirm your understanding in 2-3 sentences before proceeding.

## Step 1.5: Scout Plugins (conditional)

**Run for:** client projects, new features, multi-system work, anything touching APIs or external services.
**Skip for:** internal tooling, config changes, simple bug fixes, single-file edits.

When running:
```
Agent(subagent_type: "pr-pln-sct-plgns", model: "sonnet", prompt: "<task description from interview>")
```

Include the scout's recommendations in the plan where relevant. If nothing relevant, move on.

## Step 2: Research (silent)

Before writing the plan:
- Check what exists on disk (relevant directories, existing code, config files)
- Read any referenced files the user mentioned
- Check MEMORY.md for relevant project context
- If this plan is for a client project, read the client agent file at `~/.claude/agents/<client-name>.md`

## Step 3: Write the Plan

Read `references/plan-template.md` for the file template and formatting rules. Save to `~/.claude/plans/<generated-name>.md`.

## Rules

1. **Plan approval != build approval.** When the user approves a plan, that means the *plan* is accepted. Still ask for explicit write approval before creating or modifying files in client projects.
2. **Every phase MUST have a completion promise** with a verifiable bash command. Non-negotiable.
3. **Phases must be independently verifiable.** Don't bundle unrelated work.
4. **Keep phases small enough for a single session.** If a phase would take more than 30 minutes, split it.
5. **Name files and directories explicitly.** Don't say "create a config file."
6. **Flag dispatch candidates.** Note phases that can be dispatched with `/dispatch`.
7. **Gotchas learn from failure.** When a phase fails or the user corrects your approach, write a one-line gotcha to `~/.claude/skills/plan/proposed_gotchas.md`. Read existing `gotchas.md` and `proposed_gotchas.md` first to avoid duplicates. Proposed gotchas are reviewed during `/sync-context`. If `gotchas.md` exceeds 15 entries, ask Damon which to prune before merging.

## After Writing

1. Show the user the plan outline (phase names + one-line descriptions), then the full plan
2. Ask: "Ready to execute, or want to adjust?"
3. Once approved, ask which reviewers to dispatch:

```
Dispatch reviews? Options:
  /plan-review --mode selective  [gemini | opus | skip]
  Colleague review               [gemini | opus | skip]
```

Dispatch both reviews based on the user's choice. Use `/plan-review` (now a skill with `--mode` support for dispatch).
