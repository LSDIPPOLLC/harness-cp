#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook: inject memory index into the session context.
# Reads .github/memory/MEMORY.md and outputs it as additionalContext
# so the model starts every session aware of persistent memories.

MEMORY_DIR=".github/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

# If no memory index exists, exit cleanly
if [ ! -f "$MEMORY_INDEX" ]; then
  echo '{}'
  exit 0
fi

# Read the memory index
MEMORY_CONTENT=$(cat "$MEMORY_INDEX")

# If the index is empty or just has the header, skip
if [ "$(wc -l < "$MEMORY_INDEX")" -lt 3 ]; then
  echo '{}'
  exit 0
fi

# Output JSON with memory content as additional context
jq -n --arg content "$MEMORY_CONTENT" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Memory system active. Memory index:\n\n" + $content + "\n\nRead individual memory files from .github/memory/ when relevant to the current task. When you learn something that should persist, write a memory file and update the index.")
  }
}'
