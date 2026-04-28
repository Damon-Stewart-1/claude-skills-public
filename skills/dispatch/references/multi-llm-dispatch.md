# Multi-LLM Dispatch

When dispatching to non-Claude LLMs, the task still runs through `claude -p` but the spawned Claude calls the target LLM's API via a wrapper script.

## Choosing the Target LLM

| Target | When to use | How it works |
|--------|-------------|--------------|
| Claude | Code tasks, file edits, multi-step work | Direct `claude -p` execution |
| Gemini | Reviews, second opinions, long analysis | `claude -p` calls a Gemini API wrapper |
| ChatGPT | Alternative perspective, specific models | `claude -p` calls an OpenAI API wrapper |

## Pattern

The spawned Claude's task should be:

1. Write the full prompt to a temp file using the Write tool
2. Run the API wrapper script with the prompt file as input
3. Write the response to the output file

This keeps the Bash command short and avoids multi-thousand-character inline prompts that cause permission denial loops.

## Wrapper scripts

You need to bring your own wrapper scripts for Gemini and ChatGPT. Each should accept a prompt file and a model flag and return the response to stdout. Store them somewhere on your PATH and reference them in the dispatch prompt.

Example interface:

```bash
# Gemini
bash gemini-api.sh -f /tmp/prompt.txt -m gemini-2.5-pro -t 16384

# ChatGPT
bash chatgpt-api.sh "$(cat /tmp/prompt.txt)" gpt-4o
```

## API key handling

Your wrapper scripts need access to API keys. The cleanest pattern is a sourced cache file that sets env vars, rather than hardcoding keys or passing them as arguments:

```bash
source ~/.api-keys-cache && bash gemini-api.sh -f /tmp/prompt.txt
```

## Permission tier for LLM dispatches

Use unrestricted Bash: `--allowedTools "Read,Glob,Grep,Write,Bash"`

Bash must be unrestricted because the agent needs to source the key cache before calling the wrapper script, and glob-pattern Bash restrictions do not match compound commands.
