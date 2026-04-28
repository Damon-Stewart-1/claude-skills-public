# claude-skills-public

A portable set of Claude Code hooks, skills, and commands. Drop them into your own plugin and wire up the hooks you want.

## What's here

**hooks/** -- 14 shell scripts for PreToolUse/PostToolUse/UserPromptSubmit events.

| Hook | Event | What it does |
|------|-------|--------------|
| `env-guard.sh` | PreToolUse(Bash) | Blocks Bash commands that would expose secrets in shell output |
| `secrets-write-guard.sh` | PostToolUse(Write/Edit) | Detects hardcoded API keys after writes to non-.env files and blocks commit |
| `secrets-env-gate.sh` | PreToolUse(Write) | Gates writes to `.env` files, prompts for 1Password assessment |
| `no-em-dashes.sh` | PreToolUse(Write/Edit) | Blocks em dashes and en dashes in content files |
| `no-ai-filler.sh` | PreToolUse(Write/Edit) | Blocks AI filler phrases ("certainly", "absolutely", etc.) |
| `no-fake-urls.sh` | PreToolUse(Write/Edit) | Blocks placeholder URLs like `example.com` in source files |
| `no-placeholders.sh` | PreToolUse(Write/Edit) | Blocks `TODO`, `PLACEHOLDER`, `YOUR_VALUE_HERE` in writes |
| `protect-main.sh` | PreToolUse(Bash) | Blocks direct pushes to main/master |
| `no-curious.sh` | PreToolUse(Bash) | Blocks exploratory commands outside the task scope |
| `figma-logo-qc.sh` | PreToolUse(Write/Edit) | Flags placeholder rectangles used in place of real logo components |
| `plan-quality.sh` | PreToolUse(Write) | Checks plan files for completion promises before saving |
| `plan-gotchas-check.sh` | PreToolUse(Write) | Reminds Claude to read gotchas before writing a plan |
| `prettier-format.sh` | PostToolUse(Write/Edit) | Auto-formats JS/TS/CSS files after writes |
| `block-writes-until-review-read.sh` | PreToolUse(Write/Edit) | Blocks implementation writes until a plan review is acknowledged |
| `read-sources-before-responding.sh` | UserPromptSubmit | Detects plan/file references in prompts and injects a read reminder |
| `git-pre-commit.sh` | (manual install) | Pre-commit hook that checks staged files for hardcoded secrets |

See `hooks/hooks.json` for the full event/matcher config to paste into your `settings.json`.

**skills/** -- Invokable with `/skill-name` in any Claude Code session.

| Skill | What it does |
|-------|--------------|
| `plan` | Interview-style planning. Asks targeted questions, writes a phased plan with verifiable completion promises to `~/.claude/plans/`. |
| `dispatch` | Sends a task to a background Claude process. Handles permission tiers, model selection, job IDs, and output routing. |
| `jobs` | Lists and inspects background dispatch jobs. |
| `plan-review` | Dispatches a Gemini or Opus review of a plan file. Outputs a structured critique with a risk rating. |
| `preflight` | Runs sanity checks before a long autonomous session: context headroom, locked files, clear done criteria, iteration limit. |
| `tool-suggest` | Scans installed plugins and skills, then recommends which ones apply to the current task. |
| `captain-opus` | Frames the session as a senior PM with full authority to spawn agents and dispatch. Good opener for non-trivial sessions. |

**references/** -- Plain markdown docs Claude reads during skill execution.

- `gotchas.md` -- Planning pitfalls observed in real sessions
- `plugin-creation.md` -- Correct plugin structure and manifest format
- `ralph-usage.md` -- Iteration limits and safe defaults for autonomous loops
- `security-checklist.md` -- Mandatory checks before commits, deploys, and middleware changes

## Installation

These are designed to load as a Claude Code plugin. The quickest path:

```bash
git clone https://github.com/Damon-Stewart-1/claude-skills-public.git ~/.claude/plugins/claude-skills-public
```

Then add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "claude-skills-public": true
  }
}
```

Restart Claude Code. Skills are available immediately as `/plan`, `/dispatch`, etc.

To enable hooks, paste the relevant entries from `hooks/hooks.json` into the `hooks` array in your `settings.json`.

## Notes

- Hook scripts must be executable: `chmod +x ~/.claude/plugins/claude-skills-public/hooks/*.sh`
- `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` in command paths. Claude Code sets this env var automatically when loading a plugin -- it resolves to the plugin's root directory. You do not need to set it yourself.
- `secrets-write-guard.sh` is intentionally PostToolUse. `.env` files are gated PreToolUse by `secrets-env-gate.sh`. The write-guard catches hardcoded secrets in all other file types after the write, before the session continues.
- `plan` skill writes plans to `~/.claude/plans/` and reads `~/.claude/skills/plan/gotchas.md` for pitfall avoidance. Both paths are created on first use.
- `dispatch` expects Claude Code CLI on your PATH as `claude`. The dispatch script handles Homebrew PATH initialization for background subshells automatically.

## Requirements

- Claude Code CLI
- macOS or Linux (hooks use bash)
- `prettier` on PATH (optional, for `prettier-format.sh`)
