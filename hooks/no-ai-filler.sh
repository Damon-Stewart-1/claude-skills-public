#!/bin/bash
# PostToolUse hook: Warns on AI-authored prose tells.
# Matcher: Edit|Write|MultiEdit | Timeout: 5s
#
# Two passes:
#   1. ai-filler-blocklist.txt   marketing/SEO filler. Runs on all writes.
#   2. ai-register-tells.txt     explanatory/academic AI register tells.
#                                Only runs on prose files (.md, .mdx, .txt,
#                                .rst, .markdown).
# Plus a structural check for repeated "The [Abstract Noun]" paragraph
# openers, which is a strong AI tell that no phrase list can catch.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export AI_FILLER_LIST="$SCRIPT_DIR/ai-filler-blocklist.txt"
export AI_REGISTER_LIST="$SCRIPT_DIR/ai-register-tells.txt"

INPUT=$(cat)
export AI_HOOK_INPUT="$INPUT"

RESULT=$(python3 - <<'PY'
import sys, json, os, re

PROSE_EXTS = {'.md', '.mdx', '.txt', '.markdown', '.rst'}

def load_phrases(path):
    if not path or not os.path.exists(path):
        return []
    out = []
    with open(path) as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith('#'):
                continue
            out.append(s)
    return out

def find_match(text_lower, phrases):
    for p in phrases:
        if p.lower() in text_lower:
            return p
    return None

def is_prose_path(path):
    if not path:
        return False
    _, ext = os.path.splitext(path.lower())
    return ext in PROSE_EXTS

def detect_abstract_openers(text):
    paragraphs = [p.strip() for p in re.split(r'\n\s*\n', text) if p.strip()]
    opener_re = re.compile(
        r'^(The|This|That|These|Those)\s+'
        r'(structural|underlying|deeper|fundamental|essential|core|central|'
        r'real|true|key|critical|crucial|primary|main|broader|larger|'
        r'mechanism|diagnostic|takeaway|insight|paradox|tension|challenge|'
        r'question|problem|issue|answer|alternative|shift|throughline|'
        r'through-line|implication|consequence|reason|driver|factor|'
        r'pattern|dynamic|architecture|framework|distinction|difference)'
        r'\b',
        re.IGNORECASE,
    )
    streak = 0
    examples = []
    for p in paragraphs:
        first_line = p.splitlines()[0].lstrip('>*-#> \t')
        if opener_re.match(first_line):
            streak += 1
            examples.append(first_line[:80])
            if streak >= 3:
                return examples[:3]
        else:
            streak = 0
            examples = []
    return None

raw = os.environ.get('AI_HOOK_INPUT', '')
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

ti = data.get('tool_input', {}) or {}
file_path = ti.get('file_path', '') or ti.get('notebook_path', '')

text = ti.get('new_string', '') or ti.get('content', '')
if not text and 'edits' in ti:
    text = '\n'.join(e.get('new_string', '') for e in ti.get('edits', []))

if not text:
    sys.exit(0)

text_lower = text.lower()

filler_phrases = load_phrases(os.environ.get('AI_FILLER_LIST'))
m = find_match(text_lower, filler_phrases)
if m:
    print(json.dumps({'kind': 'filler', 'phrase': m}))
    sys.exit(0)

if is_prose_path(file_path):
    register_phrases = load_phrases(os.environ.get('AI_REGISTER_LIST'))
    m = find_match(text_lower, register_phrases)
    if m:
        print(json.dumps({'kind': 'register', 'phrase': m}))
        sys.exit(0)

    openers = detect_abstract_openers(text)
    if openers:
        print(json.dumps({'kind': 'openers', 'examples': openers}))
        sys.exit(0)
PY
)

if [ -z "$RESULT" ]; then
  exit 0
fi

KIND=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('kind',''))" 2>/dev/null)

case "$KIND" in
  filler)
    PHRASE=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('phrase',''))")
    REASON="AI filler phrase detected: '${PHRASE}'. Rewrite with specific, concrete language."
    ;;
  register)
    PHRASE=$(echo "$RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('phrase',''))")
    REASON="AI register tell detected: '${PHRASE}'. Cut the meta-pointer. State the thing directly in operator voice."
    ;;
  openers)
    EXAMPLES=$(echo "$RESULT" | python3 -c "import sys, json; print(' | '.join(json.load(sys.stdin).get('examples', [])))")
    REASON="Multiple consecutive paragraphs open with abstract noun frames (e.g., '${EXAMPLES}'). Strong AI register tell. Lead paragraphs with what someone does, decides, or sees, not 'The [abstract noun]'."
    ;;
  *)
    exit 0
    ;;
esac

REASON_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$REASON")
echo "{\"decision\":\"warn\",\"reason\":${REASON_JSON}}"
exit 0
