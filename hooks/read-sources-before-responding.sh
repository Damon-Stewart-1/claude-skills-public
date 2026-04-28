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

# ----- Tier 2: plan slugs by name (with stopwords) -----
# Push the per-file processing into Python for speed (single subprocess).
# Stopwords filter out generic project nouns so they don't count toward
# the 2-token consecutive match.
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
matches = []
try:
    for root, dirs, files in os.walk(plans_dir):
        # Cap recursion at depth 2 (PLANS_DIR + one subdir)
        depth = root[len(plans_dir):].count(os.sep)
        if depth > 1:
            dirs[:] = []
            continue
        for f in files:
            if not f.endswith(".md"):
                continue
            base_lc = f[:-3].lower()
            tokens = base_lc.split("-")
            # Need at least 2 non-stopword content tokens of length >= 3 in
            # the slug, otherwise too generic to match.
            content_count = sum(1 for t in tokens if t not in stopwords and len(t) >= 3)
            if content_count < 2:
                continue
            matched = False
            # Check adjacent token pairs as they appear in the original slug.
            # Skip pairs where both tokens are stopwords or short noise.
            for i in range(len(tokens) - 1):
                a, b = tokens[i], tokens[i+1]
                if (a in stopwords or len(a) < 3) and (b in stopwords or len(b) < 3):
                    continue
                pair = a + " " + b
                if re.search(r"\b" + re.escape(pair) + r"\b", prompt_lc):
                    matched = True
                    break
            # Fallback: literal kebab slug appears verbatim in prompt.
            if not matched and base_lc in prompt_lc:
                matched = True
            if matched:
                matches.append(os.path.join(root, f))
                if len(matches) >= 50:
                    break
        if len(matches) >= 50:
            break
except Exception:
    pass
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

# Cap candidates
if [ "${#DEDUPED[@]}" -gt "$MAX_CANDIDATES" ]; then
  DEDUPED=("${DEDUPED[@]:0:$MAX_CANDIDATES}")
fi

# Nothing matched: stay silent.
if [ "${#DEDUPED[@]}" -eq 0 ] && [ "$AGENT_HIT" -eq 0 ] && [ "$PHASE_VERSION_HIT" -eq 0 ]; then
  exit 0
fi

# Emit critical-instruction block.
{
  echo "<critical-instruction>"
  echo "The user's prompt references local material. Use the Read tool on each candidate source below before responding. Do not answer from briefings, summaries, or prior memory of these files. If a referenced file is not relevant, say so explicitly rather than skipping the Read."
  echo ""
  if [ "${#DEDUPED[@]}" -gt 0 ]; then
    echo "Candidate sources:"
    for c in "${DEDUPED[@]}"; do
      echo "- $c"
    done
    echo ""
  fi
  if [ "$AGENT_HIT" -eq 1 ]; then
    echo "The prompt references agent or dispatch output. Check ~/.claude/jobs/ for the most recent .md files and any agent results in this conversation before answering."
    echo ""
  fi
  echo "If the user referenced something you cannot identify from this list, ask which file they mean. Do not guess."
  echo "</critical-instruction>"
} 2>/dev/null

exit 0
