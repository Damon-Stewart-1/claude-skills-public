# Multi-LLM Dispatch

When dispatching to non-Claude LLMs, the task still runs through `claude -p` but the spawned Claude calls the target LLM's API script.

## Choosing the Target LLM

| Target  | When to use                             | How it works                          |
|---------|-----------------------------------------|---------------------------------------|
| Claude  | Code tasks, file edits, multi-step work | Direct `claude -p` execution          |
| Gemini  | Reviews, second opinions, long analysis | `claude -p` calls `gemini-api.sh`     |
| ChatGPT | Alternative perspective, specific models| `claude -p` calls `chatgpt-api.sh`    |

## Gemini

Script: `~/.claude/plugins/gemini-subagent/scripts/gemini-api.sh`

Flags: `-f /path/to/prompt.txt -m MODEL -t TOKENS`

Models:
- `gemini-3-flash-preview` (fast)
- `gemini-3-pro-preview` (complex)
- `gemini-2.5-flash` (stable fast)
- `gemini-2.5-pro` (stable pro, default for reviews)

Default: `gemini-2.5-pro`, `-t 16384` for long output.

## ChatGPT

Script: `~/.claude/plugins/chatgpt-subagent/scripts/chatgpt-api.sh`

Args: `"prompt" MODEL` (positional)

Models: `gpt-4o` (default), `gpt-4o-mini`, `o3-mini`

For file-based prompts: `bash chatgpt-api.sh "$(cat /tmp/prompt.txt)" gpt-4o`

## System Prompt Template for LLM Dispatches

The spawned Claude's task should be:
1. Write the full prompt to `/tmp/llm-prompt-${JOB_ID}.txt` using the Write tool
2. Run: `source ~/.api-keys-cache && bash <SCRIPT_PATH> <ARGS>`
3. Write the response to the output file

This keeps the Bash command short and avoids multi-thousand-character inline prompts that cause permission denial loops.

## Permission Tier for LLM Dispatches

Use unrestricted Bash: `--allowedTools "Read,Glob,Grep,Write,Bash"`

Bash must be unrestricted because the agent may need to `source ~/.api-keys-cache` before calling the script, and glob patterns on Bash don't match compound commands.
