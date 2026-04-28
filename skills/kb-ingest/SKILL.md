---
name: kb-ingest
description: Run kb-ingest --queue to show unprocessed KB raw files, then walk through ingesting them one at a time. Use when the user says "/kb-ingest", "ingest kb", "what's in my kb queue", or "kb queue".
user_invocable: true
---

# KB Ingest

Run kb-ingest --queue to show the current queue, then offer to ingest files one at a time.

## What to do

1. Run: `kb-ingest --queue`

2. Print the queue output for the user.

3. If the queue is empty, say: "Nothing waiting in the queue. Drop notes in Apple Notes AppleNotesCapture or run kb-add to capture new content."

4. If files are waiting, ask: "Which would you like to ingest? Give me a number or say 'all worth ingesting' and I'll filter out obvious test/junk files."

5. For each file the user wants to ingest, run it directly in the terminal:
   `! kb-ingest <filepath>`
   The script will show a preview and ask for y/n confirmation before writing anything.

6. After ingesting, remind the user they can run `kb-open` to browse new pages in Obsidian.

## Notes
- Never batch-ingest without user confirmation per file
- kb-ingest is interactive: it requires a y/n response before Sonnet writes wiki pages
- The queue only shows files not yet logged in ~/kb/craft_wiki/log.md
