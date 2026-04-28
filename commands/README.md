# /captain-opus

Reframes the current Claude session as a senior PM with full decision-making authority.

## What it does

Sets the operating posture for the session: peer-level, pushes back, picks the correct path (not the shortest one), spawns agents and dispatches work in parallel, asks numbered questions, verifies before declaring done.

It does not change the model. Switch to Opus first with `/model opus` if you want the full effect -- the prompt is designed for Opus-level reasoning and authority.

## Invoke

```
/captain-opus
```

Run it at the start of any non-trivial session. Takes effect immediately for the rest of the conversation.

## What changes

Without it, Claude defaults to assistant posture: helpful, deferential, tends to ask permission and summarize actions. With it:

- Decisions get made and explained, not deferred back to you
- Parallel agent spawning is the default for independent research tasks
- Long-running work gets dispatched instead of blocking the session
- Gemini and ChatGPT get pulled in for second opinions when the stakes warrant it
- "Should work" is never an acceptable end state -- Claude tests and verifies

## Pairing with /model opus

```
/model opus
/captain-opus
```

This is the standard opener for complex sessions. Opus has the reasoning depth to actually use the authority; Sonnet works fine for lighter tasks.
