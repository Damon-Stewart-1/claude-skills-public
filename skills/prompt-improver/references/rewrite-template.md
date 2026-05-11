# Rewrite Templates

Three skeletons, one per tier. Fill in the angle-bracket placeholders, drop sections that do not apply.

---

## One-shot template (~5 lines)

For low-stakes, run-once prompts. No XML, no examples, no CoT.

```text
You are <role>. <Task statement, imperative verb>.

Output: <format and length>.
<One quality modifier if helpful, e.g. "Be specific and concrete.">
```

**Example fill:**

```text
You are a senior B2B copywriter. Rewrite the following Slack message to my CTO so it is direct, decision-ready, and under 60 words.

Output: a single paragraph, no greetings or sign-offs.
Lead with the ask, then context.
```

---

## Standard template (~25 lines)

For medium-stakes prompts, single use OR low-stakes templated prompts. Adds XML inputs, numbered steps, output format, success criteria.

```text
You are <role>. Your task is to <task>.

<inputs>
<input_name_1>
{{variable_1}}
</input_name_1>

<input_name_2>
{{variable_2}}
</input_name_2>
</inputs>

Follow these steps:
1. <step>
2. <step>
3. <step>

Output format:
<exact format spec, e.g. "A single label from this set: bug | feature | question">

Success criteria: <one line, e.g. "The label matches what a senior support engineer would pick.">

Scope: <one line, e.g. "Output only the label. No explanation.">
```

---

## Interview template (~50 plus lines)

For high-stakes, repeatedly-used, or accuracy-critical prompts. Full Anthropic-style rewrite.

```text
You are <role>. Your task is to <task>.

<context>
{{any background or domain context}}
</context>

<inputs>
<input_name_1>
{{variable_1}}
</input_name_1>

<input_name_2>
{{variable_2}}
</input_name_2>
</inputs>

<examples>
<example>
<input>...</input>
<reasoning>...</reasoning>
<output>...</output>
</example>

<example>
<input>...</input>
<reasoning>...</reasoning>
<output>...</output>
</example>

<example>
<input>...</input>
<reasoning>...</reasoning>
<output>...</output>
</example>
</examples>

Follow these steps:
1. <step>
2. <step>
3. <step>
4. <step>

Wrap your reasoning in <analysis> tags. Inside, address each step in order. Cite specific phrases from the inputs.

After your analysis, provide your final answer in this format:
<exact format spec>

Success criteria: <one line>

Scope: <what to do, what not to do, anti-patterns to avoid>

Anti-hallucination: Never speculate about content you have not opened. If the inputs reference external files or data, read them before answering.
```

---

## Filling notes

- **Role:** be specific. "Senior support engineer with 5 years on a B2B SaaS team" beats "helpful assistant."
- **Inputs:** name them by what they are, not generic placeholders. `<ticket_title>` not `<input_1>`.
- **Steps:** make them verbs, not nouns. "Identify the user's intent" not "Intent identification."
- **Output format:** show the literal shape if possible. "One label from: bug | feature | question."
- **Success criteria:** the test the answer must pass. Not a goal, a check.
- **Examples (interview only):** make them diverse. Cover an obvious case, an edge case, and an ambiguous case.
