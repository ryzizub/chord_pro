#!/usr/bin/env bash
# PreToolUse on Edit/Write/MultiEdit/NotebookEdit.
#
# - deny edits outside the repository
# - deny edits to generated or local-only output (coverage/, .dart_tool/, build/)
# - ask before editing chordpro-spec-checklist.md, the spec ground truth
set -euo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | python3 -c '
import json, sys
i = json.load(sys.stdin).get("tool_input", {})
print(i.get("file_path") or i.get("notebook_path") or "")
')"

[ -z "$path" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
root="$(cd "$root" && pwd -P)"
case "$path" in
  /*) abs="$path" ;;
  *) abs="$PWD/$path" ;;
esac
abs="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$abs")"

decide() {
  python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PreToolUse",
  "permissionDecision": sys.argv[1],
  "permissionDecisionReason": sys.argv[2],
}}))' "$1" "$2"
  exit 0
}

# Claude's own files (memory, plans, scratchpad) live outside the repo and
# are not this hook's business.
case "$abs" in
  "$HOME"/.claude/* | /tmp/* | /mnt/*) exit 0 ;;
esac

case "$abs" in
  "$root"/*) ;;
  *) decide deny "$path is outside the repository ($root). Edit files in this checkout only." ;;
esac

rel="${abs#"$root"/}"
case "$rel" in
  coverage/* | .dart_tool/* | build/*)
    decide deny "$rel is generated output. Change the source or rerun the tool instead." ;;
  chordpro-spec-checklist.md)
    decide ask "chordpro-spec-checklist.md is the spec ground truth; it changes only when chordpro.org does or an audit gap closes (.claude/rules/spec-audit.md)." ;;
esac

exit 0
