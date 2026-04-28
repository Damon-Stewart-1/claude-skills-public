# Section Rules

- Omit any section with nothing to say, except `## Active Project`, `## Session State`, and `## Your Next Action` (always required)
- `## Your Next Action` is always the last section, generated after all other sections
- Must be an executable instruction, not a description
- If the next action is genuinely unclear: `TASK: Clarify the primary goal for this session. Ask Damon what he wants to tackle first.`
- Never hallucinate file paths or commands. Only reference files confirmed to exist this session.

## Sanitization Patterns

Before assembling output, scan the entire handover draft for secrets and replace with `[REDACTED -- see Keychain or passwords app]`:

### Exact Prefix Matches
- `sk-` (OpenAI, Anthropic API keys)
- `xoxb-`, `xoxp-`, `xoxs-` (Slack tokens)
- `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` (GitHub tokens)
- `glpat-` (GitLab tokens)
- `AKIA` (AWS access keys)
- `shpat_`, `shpss_`, `shpca_` (Shopify tokens)
- `sq0atp-`, `sq0csp-` (Square tokens)
- `SG.` (SendGrid keys)
- `key-` (generic API keys when followed by 20+ alphanumeric chars)

### Pattern Matches
- `Bearer [A-Za-z0-9._\-]{20,}` (auth headers)
- `Basic [A-Za-z0-9+/=]{20,}` (base64 auth)
- Strings matching `[A-Za-z0-9+/]{40,}={0,2}` (base64 tokens, 40+ chars)
- Connection strings: `postgres://`, `mysql://`, `mongodb://`, `redis://` with credentials
- `password\s*[:=]\s*\S+` (password assignments)

### Verbal Secrets
- Any value explicitly identified as a secret, password, token, or key during the conversation
