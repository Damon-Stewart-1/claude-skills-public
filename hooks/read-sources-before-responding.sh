#!/usr/bin/env bash
# read-sources-before-responding.sh
# UserPromptSubmit hook: scans the prompt for references to local artifacts
# (plan files, paths, phase/version refs, dispatch jobs, agent output) and
# emits a critical-instruction block telling Claude to Read those sources
# before answering.
#
# Stdin: {"prompt": "..."} JSON
# Stdout: appended to the user's prompt as context (non-blocking)
# Exit 0 always; failures are silent.

set -o pipefail

PLANS_DIR="${HOME}/.claude/plans"
NOTES_DIR="${HOME}/.claude/notes"
JOBS_DIR="${HOME}/.claude/jobs"

# Hard cap on output and runtime; never block legitimate prompts.
MAX_CANDIDATES=12

# Portability shim: BSD stat (macOS) vs GNU stat (Linux).
if stat -f '%m' / >/dev/null 2>&1; then
  STAT_FMT_MTIME_PATH=(stat -f '%m %N')
else
  STAT_FMT_MTIME_PATH=(stat -c '%Y %n')
fi

# Read prompt from stdin.
PROMPT="$(python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get("prompt", ""))
except Exception:
    pass
' 2>/dev/null)" || exit 0

# Empty prompt: nothing to do.
[ -z "$PROMPT" ] && exit 0

# Lowercased copy for case-insensitive matching.
PROMPT_LC="$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')"

CANDIDATES=()

# ----- Tier 1: explicit paths -----
# Match common path roots (~ and absolute $HOME paths).
while IFS= read -r path; do
  [ -z "$path" ] && continue
  expanded="${path/#\~/$HOME}"
  if [ -e "$expanded" ]; then
    CANDIDATES+=("$expanded")
  fi
done < <(printf '%s\n' "$PROMPT" | grep -oE "(~|${HOME})[A-Za-z0-9._/-]+(/[A-Za-z0-9._-]+)*\\.(md|txt|html|json|csv|py|sh|js|ts|tsx|jsx|css|yml|yaml)" 2>/dev/null | head -20)

# Bare directory references like ~/.claude/plans/foo (without extension)
while IFS= read -r path; do
  [ -z "$path" ] && continue
  expanded="${path/#\~/$HOME}"
  if [ -e "$expanded" ]; then
    CANDIDATES+=("$expanded")
  fi
done < <(printf '%s\n' "$PROMPT" | grep -oE "(~|${HOME})/[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+){0,4}" 2>/dev/null | head -10)

# Tier 1b: paths with spaces. Bash regex extraction can't handle these
# reliably, so delegate to Python with a known-roots whitelist.
SPACE_PATHS="$(PROMPT="$PROMPT" HOME_DIR="$HOME" python3 -c '
import os, sys
prompt = os.environ.get("PROMPT", "")
home = os.environ.get("HOME_DIR", "")
roots = [
    "~/Earned Impact Rebrand",
    "~/Library/CloudStorage",
    "~/Claude-Stuff",
    "~/Downloads",
    f"{home}/Earned Impact Rebrand",
    f"{home}/Library/CloudStorage",
]
hits = []
for root in roots:
    idx = 0
    while True:
        i = prompt.find(root, idx)
        if i < 0:
            break
        # Hard terminators: quotes, newlines, brackets that never appear in paths.
        end = i + len(root)
        while end < len(prompt) and prompt[end] not in "\n\r\"`<>|":
            end += 1
        # Trim trailing sentence punctuation but preserve internal spaces.
        candidate = prompt[i:end].rstrip(" .,;:)]}\t")
        expanded = candidate.replace("~", home, 1) if candidate.startswith("~") else candidate
        # Walk backward by space until we find a path that exists. Handles
        # trailing words like "please" or "for context".
        while expanded and not os.path.exists(expanded):
            sp = expanded.rfind(" ")
            if sp <= len(home):
                break
            expanded = expanded[:sp]
        if expanded and os.path.exists(expanded):
            hits.append(expanded)
        idx = end
print("\n".join(hits))
' 2>/dev/null)"
if [ -n "$SPACE_PATHS" ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    CANDIDATES+=("$p")
  done <<<"$SPACE_PATHS"
fi

# ----- Tier 2: plan slugs by name -----
# Two passes in one Python subprocess:
#
# Pass A (prefix sweep): if any contiguous multi-word prefix of the slug
# (2+ tokens joined by spaces) appears verbatim in the prompt, include ALL
# files sharing that prefix. "command center" in prompt → every
# command-center-*.md file, regardless of what comes after.
#
# Pass B (any-token match): if 2+ non-stopword slug tokens each appear
# anywhere in the prompt (order-independent), count as a match. This replaces
# the old adjacent-pair requirement that missed files like command-center-phase2
# when the prompt said "command center" but not "center phase".
if [ -d "$PLANS_DIR" ]; then
  TIER2_MATCHES="$(PROMPT_LC="$PROMPT_LC" PLANS_DIR="$PLANS_DIR" python3 -c '
import os, re, sys
plans_dir = os.environ["PLANS_DIR"]
prompt_lc = os.environ["PROMPT_LC"]
stopwords = {
    "plan", "dashboard", "page", "doc", "brief", "spec", "notes", "report",
    "file", "weekly", "daily", "project", "client",
    "the", "a", "an", "and", "or", "for", "with", "from",
}

# Collect all .md files first so we can do the prefix-group sweep.
all_files = []
try:
    for root, dirs, files in os.walk(plans_dir):
        depth = root[len(plans_dir):].count(os.sep)
        if depth > 1:
            dirs[:] = []
            continue
        for f in files:
            if f.endswith(".md"):
                all_files.append(os.path.join(root, f))
except Exception:
    pass

# Pass A: build a set of prefixes (2+ tokens) found in the prompt.
# Then flag every file whose slug starts with a matching prefix.
prefix_matched = set()
for fpath in all_files:
    base_lc = os.path.basename(fpath)[:-3].lower()
    tokens = base_lc.split("-")
    for length in range(2, len(tokens) + 1):
        prefix = " ".join(tokens[:length])
        if re.search(r"\b" + re.escape(prefix) + r"\b", prompt_lc):
            # Record the prefix so all siblings get picked up.
            prefix_matched.add(prefix)

# Collect all files matching any found prefix.
matches = []
seen = set()
for fpath in all_files:
    base_lc = os.path.basename(fpath)[:-3].lower()
    tokens = base_lc.split("-")
    for length in range(2, len(tokens) + 1):
        prefix = " ".join(tokens[:length])
        if prefix in prefix_matched and fpath not in seen:
            matches.append(fpath)
            seen.add(fpath)
            break

# Pass B: any-token match for files not already caught by Pass A.
for fpath in all_files:
    if fpath in seen:
        continue
    base_lc = os.path.basename(fpath)[:-3].lower()
    tokens = base_lc.split("-")
    content_tokens = [t for t in tokens if t not in stopwords and len(t) >= 3]
    if len(content_tokens) < 2:
        continue
    hit_count = sum(1 for t in content_tokens if re.search(r"\b" + re.escape(t) + r"\b", prompt_lc))
    if hit_count >= 2:
        matches.append(fpath)
        seen.add(fpath)
    if len(matches) >= 50:
        break

print("\n".join(matches))
' 2>/dev/null)"
  if [ -n "$TIER2_MATCHES" ]; then
    while IFS= read -r m; do
      [ -z "$m" ] && continue
      CANDIDATES+=("$m")
    done <<<"$TIER2_MATCHES"
  fi
fi

# ----- Tier 3: phase/version references -----
PHASE_VERSION_HIT=0
if printf '%s' "$PROMPT" | grep -qiE '\bv[0-9]+\b.*\bphase\b' || \
   printf '%s' "$PROMPT" | grep -qiE '\bphase\s+[0-9.]+\b' || \
   printf '%s' "$PROMPT" | grep -qiE '\bv[0-9]+\s+(spec|plan|brief)\b'; then
  PHASE_VERSION_HIT=1
  versions="$(printf '%s' "$PROMPT" | grep -oiE '\bv[0-9]+\b' | tr '[:upper:]' '[:lower:]' | sort -u)"
  if [ -d "$PLANS_DIR" ]; then
    # Single find pass; filter all version tokens with one grep.
    if [ -n "$versions" ]; then
      versions_pat="$(printf '%s' "$versions" | tr '\n' '|' | sed 's/|$//')"
      if [ -n "$versions_pat" ]; then
        while IFS= read -r match; do
          [ -z "$match" ] && continue
          CANDIDATES+=("$match")
        done < <(find "$PLANS_DIR" -maxdepth 2 -type f -name '*.md' 2>/dev/null \
                  | grep -iE "(${versions_pat})" \
                  | head -15)
      fi
    fi
  fi
fi

# ----- Tier 5: agent/dispatch output references -----
AGENT_HIT=0
if printf '%s' "$PROMPT_LC" | grep -qE "\b(dispatch job|the agent|agent['’]s output|the review|gemini said|chatgpt said|subagent['’]s report|the subagent|reviewer said)\b"; then
  AGENT_HIT=1
  if [ -d "$JOBS_DIR" ]; then
    while IFS= read -r job_md; do
      [ -z "$job_md" ] && continue
      CANDIDATES+=("$job_md")
    done < <(find "$JOBS_DIR" -maxdepth 1 -type f -name '*.md' -exec "${STAT_FMT_MTIME_PATH[@]}" {} \; 2>/dev/null \
              | sort -rn | head -3 | awk '{$1=""; sub(/^ /, ""); print}')
  fi
fi

# Dedupe candidates while preserving first-seen order. awk handles paths
# with spaces and runs in a single subprocess.
DEDUPED=()
if [ "${#CANDIDATES[@]}" -gt 0 ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    DEDUPED+=("$line")
  done < <(printf '%s\n' "${CANDIDATES[@]}" | awk 'NF && !seen[$0]++')
fi

# Cap candidates -- warn rather than silently drop.
DROPPED_COUNT=0
if [ "${#DEDUPED[@]}" -gt "$MAX_CANDIDATES" ]; then
  DROPPED_COUNT=$(( ${#DEDUPED[@]} - MAX_CANDIDATES ))
  DEDUPED=("${DEDUPED[@]:0:$MAX_CANDIDATES}")
fi

# Nothing matched: stay silent.
if [ "${#DEDUPED[@]}" -eq 0 ] && [ "$AGENT_HIT" -eq 0 ] && [ "$PHASE_VERSION_HIT" -eq 0 ]; then
  exit 0
fi

# Detect full-read triggers:
# 1. Prompt contains the clear-prep sentinel (pasted handover)
# 2. Prompt contains words meaning "read everything" and files were matched
FULL_READ=0
if printf '%s' "$PROMPT" | grep -q 'CLEAR_PREP_HANDOVER'; then
  FULL_READ=1
elif printf '%s' "$PROMPT_LC" | grep -qE '\b(all|everything|every file|every one|full context|don'\''t skip|do not skip)\b' && [ "${#DEDUPED[@]}" -gt 0 ]; then
  FULL_READ=1
fi

# Size guard for Mode B: estimate total bytes before injecting.
# If combined size exceeds 150KB, fall back to Mode A with a warning.
MODE_B_SIZE_WARNING=0
if [ "$FULL_READ" -eq 1 ] && [ "${#DEDUPED[@]}" -gt 0 ]; then
  total_bytes=0
  for c in "${DEDUPED[@]}"; do
    fsize=$(stat -f%z "$c" 2>/dev/null || stat -c%s "$c" 2>/dev/null || echo 0)
    total_bytes=$(( total_bytes + fsize ))
  done
  if [ "$total_bytes" -gt 153600 ]; then
    FULL_READ=0
    MODE_B_SIZE_WARNING=1
  fi
fi

# Emit critical-instruction block.
{
  echo "<critical-instruction>"
  if [ "$FULL_READ" -eq 1 ] && [ "${#DEDUPED[@]}" -gt 0 ]; then
    echo "The user's prompt requires reading ALL of the following files in full. Their complete contents are included below. You must treat every word as read -- no summarizing, no skipping, no 'I read the relevant parts'. These are not candidates; they are required reading."
    echo ""
    for c in "${DEDUPED[@]}"; do
      echo "=== FILE: $c ==="
      cat "$c" 2>/dev/null || echo "[unreadable]"
      echo ""
      echo "=== END: $c ==="
      echo ""
    done
  else
    echo "The user's prompt references local material. Use the Read tool on each source below before responding. Do not answer from briefings, summaries, or prior memory of these files. If you believe a file is not relevant, you must ask the user before skipping it -- do not make that call unilaterally."
    echo ""
    if [ "$MODE_B_SIZE_WARNING" -eq 1 ]; then
      echo "WARNING: Matched files exceed 150KB combined. Full inline injection skipped to avoid context overflow. Read selectively but ask before skipping any file the user may consider relevant."
      echo ""
    fi
    if [ "${#DEDUPED[@]}" -gt 0 ]; then
      echo "Sources to read:"
      for c in "${DEDUPED[@]}"; do
        echo "- $c"
      done
      if [ "$DROPPED_COUNT" -gt 0 ]; then
        echo ""
        echo "WARNING: $DROPPED_COUNT additional matching file(s) were not listed due to the candidate cap. Tell the user this before responding so they can decide whether to raise the limit."
      fi
      echo ""
    fi
  fi
  if [ "$AGENT_HIT" -eq 1 ]; then
    echo "The prompt references agent or dispatch output. Check ~/.claude/jobs/ for the most recent .md files and any agent results in this conversation before answering."
    echo ""
  fi
  if [ "$FULL_READ" -eq 0 ]; then
    echo "If the user referenced something you cannot identify from this list, ask which file they mean. Do not guess."
  fi
  echo "</critical-instruction>"
} 2>/dev/null

exit 0
