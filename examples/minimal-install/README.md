# Minimal install

The smallest viable setup: clone the repo as a plugin, enable two hooks, install one skill.

## Steps

```bash
git clone https://github.com/Damon-Stewart-1/claude-skills-public.git ~/.claude/plugins/claude-skills-public
chmod +x ~/.claude/plugins/claude-skills-public/hooks/*.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "plugins": {
    "claude-skills-public": {
      "path": "~/.claude/plugins/claude-skills-public"
    }
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-em-dashes.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/secrets-write-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Restart Claude Code.

## Verify

In a Claude Code session:

```
/plan some test feature
```

Should invoke the planning skill. If you see "skill not found," the plugin path is wrong.

Then ask Claude to write a file with an em dash character in the body. The write should be blocked by `no-em-dashes.sh`. If it is not, hook scripts are not executable or the plugin path is wrong.

## What you get

- One skill: `/plan` for interview-style planning
- Two hooks: em-dash blocker and secret-write guard

That is enough to feel the value. Add more from `hooks/hooks.json` as you want them.
