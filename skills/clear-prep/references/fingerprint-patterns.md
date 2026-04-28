# File Snapshot Fingerprinting

A file is relevant if it: (1) is in the active project directory, (2) has uncommitted changes per `git status --porcelain`, or (3) was explicitly read/written this session.

## Commands

```bash
git status --porcelain          # detect dirty state (run per repo if multiple repos touched)
stat -f %m path/to/file         # modification timestamp (macOS)
```

## Output Format

```
- `path/to/file` ([clean|modified|untracked|staged], [N] min ago) -- [what changed, derived from conversation]
```

For the change description: find the user prompt that directly preceded the file write and summarize that instruction. Do NOT run `git diff`. Do NOT hallucinate generic reasons.

## Caps and Edge Cases

**Cap:** If more than 20 relevant files, list the 20 most recently modified with full entries. Append: `+ [N] additional files in [directories]. Run git status in those directories to see full list.`

**Multi-repo:** If files span multiple git repos, run `git status --porcelain` in each repo separately. Group entries by repo with a `### [repo-path]` subheading.

**Not a git repo:** Mark status "N/A".

**stat failure or permission denied:** Note inline, continue.

**No relevant files:** Omit the `## File Map` section entirely.
