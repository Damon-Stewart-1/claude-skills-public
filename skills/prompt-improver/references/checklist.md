# Prompt Diagnostic Checklist

12 axes. Each axis tagged with the tier(s) it applies to. When rewriting at a given tier, address only the axes tagged for that tier.

Tier legend: **L** = One-shot (light), **S** = Standard, **F** = Interview (full).

---

## 1. Role / system framing  [L, S, F]

Does the prompt set a role for the model? Even a single sentence ("You are a senior copy editor who writes for B2B SaaS") sharpens tone and behavior. Missing role is the most common weakness in casual prompts.

**Fix:** prepend `You are <role>. <Task statement>.`

## 2. Output format / specificity  [L, S, F]

Does the prompt say what shape the output should take? "Write something about X" leaves Claude guessing. "Write 3 bullet points, each under 15 words" does not.

**Fix:** add an `Output:` line stating format, length, structure.

## 3. XML-tagged inputs  [S, F]

When the prompt has variable inputs (`{{title}}`, `{{ticket_body}}`, document text), wrap each in a descriptive XML tag.

**Fix:** wrap inputs in `<ticket>`, `<document>`, `<user_message>`, etc.

## 4. Examples  [F]

For tasks where output quality depends on shape (classification, copy in a specific voice, structured extraction), 3 to 5 input/output examples in `<example>` tags lift accuracy substantially.

**Fix:** add `<examples>` block with 3 diverse `<example>` blocks. Each shows input, reasoning, output.

## 5. Chain-of-thought  [F]

For multi-step reasoning, classification with edge cases, or any task where the model should "show its work," instruct explicit reasoning in `<analysis>` or `<thinking>` tags before the answer.

**Fix:** add "Wrap your reasoning in `<analysis>` tags. After your analysis, provide your final answer in this format..."

## 6. Numbered steps  [S, F]

When order matters (read X, then compare to Y, then output Z), use numbered steps. Especially useful for analysis, code review, multi-document synthesis.

**Fix:** convert prose instructions into a numbered list inside the prompt.

## 7. Success criteria  [S, F]

Does the prompt say what "good enough" looks like? "The classification is correct and the reasoning cites the title or body text." This makes self-checks possible.

A success criterion is a behavioral test the answer must pass, not a goal. Be concrete.

**Pass the bar:**
- "A startup founder skims it in 30 seconds and clicks the CTA."
- "The label matches what a senior support engineer would pick on the first read."
- "Every fact in the summary appears verbatim somewhere in the source document."

**Do NOT pass the bar:**
- "The answer is good."
- "Make sure it is high quality."
- "It should be useful to the reader."

If the criterion could be true of any output, it is not a criterion. Rewrite until it would catch a wrong answer.

**Fix:** add a `Success criteria:` line, one sentence, behavioral.

## 8. Action verb vs suggestion verb  [L, S, F]

"Suggest changes" produces suggestions. "Make these changes" produces changes. Match the verb to the desired behavior.

**Fix:** swap "could you," "would you," "suggest" for direct imperatives.

## 9. Modifiers for quality  [L, S, F]

Prompts like "include as many relevant features as possible," "go beyond the basics to create a fully featured implementation," and "be thorough" measurably lift output quality on open-ended tasks.

**Fix:** add one quality modifier where appropriate.

## 10. Tell what to do, not what not to do  [L, S, F]

Negative instructions ("do not be too brief") work less reliably than positive ones ("write 4 to 6 sentences with concrete examples").

**Fix:** convert "don't X" phrasing into "do Y" phrasing.

## 11. Scope fence  [S, F]

Anti-overengineering line. "Make only the changes requested. Do not refactor surrounding code, add abstractions, or expand scope."

**Fix:** add a `Scope:` line for code or implementation prompts.

## 12. Anti-hallucination  [F]

For prompts that touch a real codebase, real files, or real data: "Investigate before answering. Read the file before making claims about it."

**Fix:** add "Never speculate about content you have not opened. If the prompt references a file or data, read it before answering."

---

## Tier coverage at a glance

| Axis | L | S | F |
|---|---|---|---|
| 1. Role | ✓ | ✓ | ✓ |
| 2. Output format | ✓ | ✓ | ✓ |
| 3. XML inputs |   | ✓ | ✓ |
| 4. Examples |   |   | ✓ |
| 5. Chain-of-thought |   |   | ✓ |
| 6. Numbered steps |   | ✓ | ✓ |
| 7. Success criteria |   | ✓ | ✓ |
| 8. Action verb | ✓ | ✓ | ✓ |
| 9. Modifiers | ✓ | ✓ | ✓ |
| 10. Tell-what-to-do | ✓ | ✓ | ✓ |
| 11. Scope fence |   | ✓ | ✓ |
| 12. Anti-hallucination |   |   | ✓ |
