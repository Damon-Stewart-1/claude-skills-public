# Platform Gotchas

- Claude Code caches shell env at session start. If tools are missing, prefix `eval "$(/opt/homebrew/bin/brew shellenv)"` or nvm init.
- Never deploy to personal Vercel account `damons-projects-e409ae32`. Always use `earned-impact-fka-amp-local`.
- Vercel KV (Upstash Redis): Use `ei-internal-kv` for internal projects, `ei-client-kv` for client projects. Connected via Upstash integration in Vercel dashboard (manual per-project step). Env vars auto-injected: `KV_URL`, `KV_REST_API_URL`, `KV_REST_API_TOKEN`, `KV_REST_API_READ_ONLY_TOKEN`, `REDIS_URL`. Client: `@vercel/kv`. Prefix all keys by project to avoid namespace collisions (e.g. `issues:ei-command-center:abc123`).
- GCP auth is via `damon@amplocal.io` on project `long-victor-488019-v2`.
- Sonnet subagents (via Agent tool) do NOT inherit `"*"` permissions from settings.local.json. For Bash-heavy tasks, execute directly or use `/dispatch` (which spawns a full CLI process with permissions).
- Remote triggers (`/schedule`) run in Anthropic's cloud, they cannot access local files. Use `/dispatch` or local cron for filesystem tasks.
- Cloud backup runs via `~/bin/watch-claude-sync.sh` (PID watcher, 30s interval) to both iCloud and Google Drive. If it breaks, check macOS Full Disk Access for the launching app.
- `~/.claude/` is a sensitive write path. The Write tool is blocked there even with `--permission-mode bypassPermissions`. Headless scripts must output to `~/Claude-Stuff/` or other non-config directories.
- `--bare` flag skips keychain auth reads. Cannot use it for headless runs without explicitly setting `ANTHROPIC_API_KEY` env var.
- Vercel native password protection on production requires $150/mo Advanced add-on. Use Edge Middleware (`middleware.js`) for password gates on Pro plan instead.
- Figma: NEVER create placeholder rectangles for logos. Always use the real component instances (Dark mark `44:9` for light bg, Inverted mark `44:12` for dark bg). This applies to any project touching the EI Figma file.
- The no-em-dashes hook blocks Write/Edit of content/UI files containing em dashes, en dashes, OR double-hyphens used as em dash substitutes (e.g., "word \-\- word"). Double hyphens are an AI tell just like em dashes. Rewrite sentences using commas, periods, colons, or parentheses instead. Code files (.ts, .py, .sh, etc.) are excluded. For HTML, only visible text is checked (not tags/attributes/style/script). When archiving old content that predates the hook, use Bash `mv`/`cp` instead.
- launchd: use `launchctl bootstrap gui/$(id -u) /path/to/plist` to load agents, not `launchctl load` (deprecated, unreliable on modern macOS). Unload with `launchctl bootout gui/$(id -u) /path/to/plist`.
- launchd plists: `ProgramArguments` does NOT expand `~/` or `$HOME`. Use full absolute paths (e.g., `~/bin/script.sh`).
- JXA / Apple Notes: Automation permission must be granted manually in System Settings > Privacy & Security > Automation before any JXA script can run silently (e.g., under launchd). Run the script once from Terminal to trigger the dialog.
- URL fetching in scripts: use Chrome `--headless=new --dump-dom <url>` for rendered HTML capture. Playwright MCP is interactive-only and cannot be called from shell scripts or dispatch jobs.
- Dispatches that reference a plan file (e.g., "read ~/.claude/plans/foo.md") will fail immediately if the file does not exist. Create the plan file before dispatching.
- Before any commit, verify `git config user.email`. Use `damon@earnedimpact.org` (primary as of April 10, 2026). Prior default was `damon@amplocal.io`. Never use laptop default.
