# Writing a custom hook

How to add your own hook on top of this plugin without forking. The pattern: write a small bash script that reads tool-call JSON on stdin, decides allow/block/warn, and prints a decision JSON on stdout.

## Hook contract

Claude Code calls your hook script with:
- A JSON blob on stdin describing the tool call
- An `event` matcher (e.g. `PreToolUse`) and a `matcher` (e.g. `Write|Edit`)

Your script must:
- Always exit 0 (Claude reads the JSON, not the exit code)
- Print a JSON decision on stdout, OR print nothing to allow

## Decision JSON shape

```json
{"decision": "block", "reason": "explanation shown to Claude"}
{"decision": "warn",  "reason": "shown to Claude as a soft note"}
```

Or print nothing. Empty stdout means "allow."

## Example: block writes that contain a forbidden word

`hooks/no-tbd.sh`:

```bash
#!/usr/bin/env bash
# Blocks writes that contain "TBD" in the content.
# Useful for preventing AI-generated drafts from shipping with placeholders.

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))")

if echo "$CONTENT" | grep -q "TBD"; then
  printf '{"decision":"block","reason":"Content contains TBD. Replace with the real value before saving."}\n'
  exit 0
fi

# Empty stdout = allow
exit 0
```

Make it executable:

```bash
chmod +x hooks/no-tbd.sh
```

Wire it up in `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/no-tbd.sh"
          }
        ]
      }
    ]
  }
}
```

## Patterns to copy from this repo

| Need | Look at |
|------|---------|
| Read tool input safely | Any hook that does `python3 -c "import sys,json; ..."` to parse stdin |
| Block on regex match | `no-em-dashes.sh`, `no-ai-filler.sh` |
| Block based on file path | `secrets-env-gate.sh` |
| Allow with a warning | `plan-gotchas-check.sh` |
| Run shell tool checks before Bash | `protect-main.sh`, `env-guard.sh` |

## Testing your hook

Add a smoke test to `tests/test_hooks.sh`. The existing tests show the pattern: pipe a fixture JSON into the hook, assert the decision matches expectations.

## Common mistakes

- **Exiting non-zero on block.** Claude Code ignores exit codes for hook decisions. The decision lives in JSON stdout. Non-zero exit kills the hook silently.
- **Printing the decision JSON to stderr.** Claude reads stdout only. Stderr is logged but not parsed.
- **Forgetting `chmod +x`.** Non-executable hook scripts fail silently.
- **Hardcoding the plugin path.** Use `${CLAUDE_PLUGIN_ROOT}` so the hook works regardless of install location.
