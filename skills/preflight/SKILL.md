---
name: preflight
description: Test all MCP servers, API keys, env vars, and GCP auth. Outputs green/red status table. Run before any session work.
user_invocable: true
---

# Preflight Check

Run a full environment health check before starting session work. Tests MCP servers, Keychain secrets, env files, GCP auth, and GitHub identity. Compares against the declared-state file at `~/.claude/preflight-state.json`.

## Arguments

- No arguments: full check of everything in declared-state
- `--client <slug>`: also run client-specific overrides from `preflight-state.json`
- `--fix`: enable auto-fix mode (still confirms before each fix)
- `--quiet`: only show failures, skip green rows

## Execution Steps

### Step 0: Load Declared State

Read `~/.claude/preflight-state.json` using the Read tool. This is the source of truth for what to check. If the file is missing, tell the user: "No preflight-state.json found. Create one at ~/.claude/preflight-state.json or I can generate a default."

Parse the JSON and extract all check categories. Initialize a results array to collect status for the final table.

### Step 1: Keychain Keys

For each entry in `keychain_keys`, run:

```bash
security find-generic-password -a "$USER" -s "SERVICE_NAME" -w >/dev/null 2>&1 && echo "OK" || echo "MISSING"
```

**Do NOT capture or display the key value.** Only check existence.

For keys with an `expires` field, calculate days until expiry from today's date. If within `warn_days_before`, mark as WARN with the expiry date.

Record result for each key:
- OK: key exists in Keychain
- WARN: key exists but approaching expiry
- FAIL: key missing from Keychain

**Auto-fix for MISSING keys** (only if `--fix`):
1. Tell the user: "KEY_NAME is missing from Keychain. Do you have the value to add it?"
2. If yes, run: `security add-generic-password -a "$USER" -s "SERVICE_NAME" -w "VALUE"`
3. If no, note it as unresolved.

### Step 2: Env Files

For each entry in `env_files`, expand `~` and check:

1. File exists:
```bash
[ -f ~/.claude/FILE_NAME ] && echo "EXISTS" || echo "MISSING"
```

2. File has correct permissions (should be 600):
```bash
stat -f "%Lp" ~/.claude/FILE_NAME
```

3. Required vars are present (check for lines starting with VAR_NAME=, value is non-empty):
```bash
grep -q '^VAR_NAME=.\+' ~/.claude/FILE_NAME && echo "SET" || echo "EMPTY"
```

**Important:** Use `grep -q` only. Do NOT read or display the file contents or token values. The env-guard hook will block any attempt to cat or echo these files via Bash.

Record result:
- OK: file exists, correct perms, all vars set
- WARN: file exists but wrong permissions (not 600)
- FAIL: file missing or required var empty

**Auto-fix for wrong permissions** (only if `--fix`):
```bash
chmod 600 FILE_PATH
```

### Step 3: MCP Server Connectivity

For each entry in `mcp_servers`:

**HTTP servers** (type: "http"): Test with a HEAD request (5s timeout):
```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 5 URL
```
- 200-399: OK
- 401/403: AUTH_ISSUE (server reachable but auth failed)
- 0 or 5xx: UNREACHABLE

**stdio servers** (type: "stdio"): Check the command is available:
```bash
command -v npx >/dev/null 2>&1 && echo "OK" || echo "MISSING"
```
For google-calendar specifically, also check the OAuth file exists:
```bash
[ -f ~/.config/gcloud/calendar-oauth.json ] && echo "OK" || echo "MISSING"
```

Record result:
- OK: reachable / command available
- WARN: reachable but auth issue (may need re-auth)
- FAIL: unreachable or command missing

**Auto-fix for AUTH_ISSUE on OAuth servers** (only if `--fix`):
Tell the user: "SERVER_NAME returned 401/403. This usually means the OAuth token expired. You may need to re-authenticate. Would you like me to open the re-auth flow?"

### Step 4: GCP Auth

Check active gcloud account and project:

```bash
gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null
```

```bash
gcloud config get-value project 2>/dev/null
```

Compare against `gcp.expected_account` and `gcp.expected_project`.

Record result:
- OK: correct account and project
- WARN: correct account, wrong project
- FAIL: wrong account or no active auth

**Auto-fix for wrong project** (only if `--fix`, with confirmation):
```bash
gcloud config set project EXPECTED_PROJECT
```

**Auto-fix for wrong account** (only if `--fix`):
Tell the user: "GCP is authenticated as CURRENT_ACCOUNT but expected EXPECTED_ACCOUNT. Run `! gcloud auth login EXPECTED_ACCOUNT` to switch."

### Step 5: GitHub Identity

```bash
gh auth status 2>&1
```

Check the output for the logged-in user. Compare against `github.expected_user`.

Also verify git config:
```bash
git config --global user.email
```

Expected: `damon@amplocal.io` (or `damon@earnedimpact.org` per April 10 switch; check current date).

Record result:
- OK: correct user, correct email
- WARN: correct user, wrong email
- FAIL: not authenticated

**Auto-fix for wrong git email** (only if `--fix`, with confirmation):
Tell the user which email is configured and which is expected. Ask before changing. If after April 10 2026, expected email is `damon@earnedimpact.org`.

### Step 6: Client Overrides (only if `--client` specified)

Look up the client slug in `client_overrides`. Run any additional checks specified there. These are informational; display as notes in the status table.

### Step 7: Output Status Table

Build and display a markdown table with all results:

```
## Preflight Results - [DATE]

| #  | Check                        | Status | Detail                              |
|----|------------------------------|--------|--------------------------------------|
| 1  | Keychain: GEMINI_API_KEY     | OK     | Present                              |
| 2  | Keychain: FIGMA_ACCESS_TOKEN | WARN   | Expires 2026-06-24 (84 days)        |
| 3  | Env: productive.env.local    | OK     | File exists, perms 600, token set    |
| 4  | MCP: slack                   | OK     | HTTP 200                             |
| 5  | MCP: google-calendar         | WARN   | OAuth file exists, needs first auth  |
| 6  | GCP: auth                    | OK     | damon@amplocal.io / long-victor...   |
| 7  | GitHub: identity             | WARN   | Email still amplocal.io, switch date passed |
```

Status formatting:
- **OK** = check passed
- **WARN** = check passed with caveats (approaching expiry, wrong but non-critical config)
- **FAIL** = check failed, blocks work

### Step 8: Summary Line

After the table, output a one-line summary:

- All OK: "Preflight complete. All [N] checks passed."
- Some warnings: "Preflight complete. [N] passed, [W] warnings. Review yellow rows."
- Any failures: "Preflight BLOCKED. [F] failures must be resolved before starting work."

If there are failures and `--fix` was passed, list the unresolved items and what the user needs to do manually.

## Important Rules

- **NEVER display, echo, or log any secret values.** Only check existence via exit codes.
- **NEVER use `cat`, `head`, or `Read` on .env.local files during preflight.** Use `grep -q` to verify var presence.
- **All Bash commands that touch secrets must use exit-code checks only**, not output capture.
- **Respect the env-guard hook.** Do not use printf/echo with token variables.
- **Auto-fixes require user confirmation.** Show what will change and wait for approval.
- The declared-state file is user-maintained. If a check is missing from the file, skip it. Do not add checks that aren't declared.
