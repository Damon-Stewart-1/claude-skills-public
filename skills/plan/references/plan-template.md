# Plan File Template

Save to `~/.claude/plans/<generated-name>.md` using this structure:

```markdown
# Plan: <descriptive title>

## Context
<2-3 sentences: what problem this solves, why now, what exists>

## Constraints
<bullet list of non-obvious constraints from the interview>

## Phase 1: <name>
<what to do, specific files to create/modify>

**Completion promise:** Run: `<bash command that verifies this phase is done>`. Expected: <what the output should show>. Output "PHASE_1_COMPLETE" when verified.

## Phase 2: <name>
...

**Completion promise:** Run: `<bash command>`. Expected: <expected output>. Output "PHASE_2_COMPLETE" when verified.

## Phase N: Verification
<final integration check, test commands, manual verification steps>

**Completion promise:** Run: `<final verification>`. Output "ALL_PHASES_COMPLETE" when verified.

---

## Risks
<2-3 things that could go wrong and how to handle them>

## Session Sizing
<which phases fit in one session vs need a break>
```

## Template Rules

- Every phase MUST have a completion promise with a bash command, not prose
- Completion promises must be copy-pasteable without modification
- Phases must be independently verifiable
- Keep phases small enough to fit in a single session
- Name files and directories explicitly ("create `~/.claude/hooks/no-curious.sh`", not "create a config file")
- Flag dispatch candidates: phases that are pure research or generation with clear done-criteria
