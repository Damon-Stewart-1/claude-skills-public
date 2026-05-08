# Worked Rewrite Examples

Three before/after pairs covering the most common ask types: classification, copywriting, and code review. Use these to pattern-match the user's task to the closest example, then borrow shape and tone.

---

## Example 1: Classification (Interview tier)

**Original (user input):**

```text
From the following list of Wikipedia article titles, identify which article this sentence came from. Respond with just the article title and nothing else.

Article titles: {{titles}}
Sentence to classify: {{sentence}}
```

**Improved:**

```text
You are an intelligent text classification system specialized in matching sentences to Wikipedia article titles. Your task is to identify which Wikipedia article a given sentence most likely belongs to, based on a provided list of article titles.

First, review the following list of Wikipedia article titles:
<article_titles>
{{titles}}
</article_titles>

Now, consider this sentence that needs to be classified:
<sentence_to_classify>
{{sentence}}
</sentence_to_classify>

Your goal is to determine which article title from the provided list best matches the given sentence. Follow these steps:

1. List the key concepts from the sentence
2. Compare each key concept with the article titles
3. Rank the top 3 most relevant titles and explain why they are relevant
4. Select the most appropriate article title that best encompasses or relates to the sentence's content

Wrap your analysis in <analysis> tags. Include the following:
- List of key concepts from the sentence
- Comparison of each key concept with the article titles
- Ranking of top 3 most relevant titles with explanations
- Your final choice and reasoning

After your analysis, provide your final answer: the single most appropriate Wikipedia article title from the list.

Output only the chosen article title, without any additional text or explanation.
```

**What changed and why:**

- Added role line for tone consistency. (Axis 1)
- Wrapped `{{titles}}` and `{{sentence}}` in semantic XML tags so the model parses them unambiguously. (Axis 3)
- Numbered the reasoning steps so the model works in order. (Axis 6)
- Added `<analysis>` tag for chain-of-thought, with explicit sub-bullets. (Axis 5)
- Stated output format strictly: "Output only the chosen article title." (Axis 2)

Source: Anthropic Console Prompt Improver documentation.

---

## Example 2: Creative copy (Standard tier)

**Original (user input):**

```text
write me a landing page for a new pricing tier called Studio for our startup customers
```

**Triage answers (assumed):** medium importance, once.

**Follow-up answers (assumed):**
1. Inputs: tier name, monthly price, top 3 features, target audience.
2. Output format: H1, subhead, 3 feature bullets, CTA.
3. Good enough: a startup founder reads it in 30 seconds and clicks the CTA.

**Improved:**

```text
You are a senior B2B copywriter who specializes in conversion-focused SaaS landing copy. Your task is to write the hero section of a pricing-tier landing page.

<inputs>
<tier_name>Studio</tier_name>
<monthly_price>$49</monthly_price>
<top_features>
1. Unlimited projects
2. Real-time collaboration with up to 5 teammates
3. Priority support with a 4-hour response SLA
</top_features>
<audience>Pre-seed and seed-stage startup founders, technical, time-poor</audience>
</inputs>

Follow these steps:
1. Write an H1 (under 10 words) that names the audience and the outcome.
2. Write a subhead (under 25 words) that says what they get and why it is for them.
3. Write 3 feature bullets, each under 15 words, leading with the user benefit.
4. Write a CTA button label (2 to 4 words) that uses an action verb.

Output format:
- H1: <text>
- Subhead: <text>
- Bullet 1: <text>
- Bullet 2: <text>
- Bullet 3: <text>
- CTA: <text>

Success criteria: a startup founder skims it in 30 seconds and clicks the CTA. The copy names them and shows them the outcome.

Scope: hero section only. No FAQ, no testimonials, no footer.
```

**What changed and why:**

- Added specific role (senior B2B copywriter). (Axis 1)
- Wrapped inputs in named XML tags. (Axis 3)
- Numbered steps in writing order. (Axis 6)
- Output format shows the literal shape. (Axis 2)
- Success criteria is a behavioral test, not a goal. (Axis 7)
- Scope fences out adjacent work. (Axis 11)

---

## Example 3: Code review (One-shot tier)

**Original (user input):**

```text
review my function and tell me if anything is wrong
```

**Triage answers (assumed):** low importance, once.

**Improved:**

```text
You are a senior software engineer doing a quick PR review. Read the function below and identify any bugs, security issues, or correctness problems.

Output: a numbered list of findings. Each finding states the line, the issue, and a one-sentence fix. Skip style nits.
Be thorough on logic and edge cases.
```

**What changed and why:**

- Added role (senior engineer doing a PR review) so the tone is direct, not tutorial. (Axis 1)
- Output format states what each finding contains. (Axis 2)
- Modifier "Be thorough on logic and edge cases" lifts depth. (Axis 9)
- "Skip style nits" tells what to do (focus on logic) instead of what not to do. (Axis 10)

---

## Pattern matching guide

| User's task type | Closest example | Default tier suggestion |
|---|---|---|
| Classification, extraction, structured output | Example 1 | Interview |
| Marketing copy, internal comms, voice-driven writing | Example 2 | Standard |
| Code review, debugging, quick analysis | Example 3 | One-shot or Standard |
| Open-ended research or strategy | Example 2 (adapt) | Standard or Interview |
| Multi-step agentic prompt with tool use | Example 1 (adapt) | Interview |
