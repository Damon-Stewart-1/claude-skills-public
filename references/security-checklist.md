# Security Checklist — Mandatory for All Projects

## 1. Never Bypass Auth via Middleware
When modifying middleware or auth logic:
- **Never exempt all API routes** (e.g., `pathname.startsWith('/api/')`) — this exposes every data and action endpoint publicly.
- Only exempt routes that have their own auth (e.g., cron routes with `CRON_SECRET`). Be explicit: `/api/cron/` not `/api/`.
- After any middleware change, verify: which routes are now unprotected? Could an unauthenticated user hit a data or mutation endpoint?
- If a new API route needs to be public, add it as a specific exception with a comment explaining why.

## 2. Never Commit Secrets to Code or Docs
Before every commit, check all staged files for:
- API keys, tokens, developer tokens, client secrets
- Passwords or password conventions (e.g., `clientname2026!`)
- OAuth refresh tokens, cron secrets, webhook URLs
- Any value that belongs in `.env`, Vercel env vars, or a passwords app

**Where secrets belong:** `.env.local` (gitignored), Vercel env vars, or passwords app. Reference them by location ("see passwords app"), never inline.

**Memory files too:** Never store actual secret values in `~/.claude/projects/*/memory/` files. Use "see passwords app" or similar references.

This applies to: source code, SOP docs, README files, memory files, comments, and commit messages.

## 3. Vercel Env Var Scoping
When adding env vars in Vercel dashboard:
- **Production only** for secrets (API keys, DB URLs, tokens) -- never expose to Preview unless required
- **Preview + Development** for non-sensitive config (feature flags, URLs)
- Always use environment-specific values: never share the production DB URL with Preview deployments
- After adding vars, redeploy for them to take effect

## 4. Git Pre-Commit Hook
Install per-repo to catch secrets before they're staged:
```bash
cp ~/.claude/hooks/git-pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
The hook checks for hardcoded API keys and common secret patterns. Install this in every new repo before the first commit.

## 5. productive.env.local Exception
`productive.env.local` is an accepted security exception -- do not flag it in reviews. It contains Productive.io credentials needed for local task logging and is explicitly gitignored.
