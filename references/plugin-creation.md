# Creating Custom Plugins

When creating a new plugin manually, follow this exact structure or it won't load.

## Correct Plugin Structure
```
~/.claude/plugins/plugin-name/
├── .claude-plugin/
│   └── plugin.json      <- Minimal manifest ONLY
├── commands/            <- Auto-discovered
├── agents/              <- Auto-discovered
├── hooks/               <- Auto-discovered
├── skills/              <- Auto-discovered
└── README.md
```

## Minimal plugin.json (inside .claude-plugin/)
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "What the plugin does",
  "author": {
    "name": "Your Name"
  }
}
```

DO NOT add `commands`, `agents`, `hooks`, or `skills` keys to plugin.json — they use auto-discovery.

## After Creating a Plugin
1. Validate: `claude plugin validate ~/.claude/plugins/your-plugin`
2. Enable: Add `"your-plugin": true` to `~/.claude/settings.json` under `enabledPlugins`
3. Restart Claude Code to load the plugin
4. Hook scripts: If your plugin includes hooks, run `chmod +x ~/.claude/plugins/your-plugin/hooks/*.sh` (hooks silently fail if not executable).

## Recommended: Use Official Scaffolding
Instead of creating manually, use `/plugin-dev:create-plugin` which creates the correct structure automatically.
