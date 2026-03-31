#!/usr/bin/env bash
set -euo pipefail

# Stop hook: prompt the model to consider saving memories before ending.
# Checks stop_hook_active to prevent infinite loops.

# Read hook input from stdin
INPUT=$(cat)

# Check if this is already a stop-hook re-entry (prevent infinite loop)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  echo '{}'
  exit 0
fi

MEMORY_DIR=".github/memory"

# Check if memory directory exists
if [ ! -d "$MEMORY_DIR" ]; then
  echo '{}'
  exit 0
fi

# Prompt the model to consider saving memories
jq -n '{
  "hookSpecificOutput": {
    "decision": "block",
    "reason": "Before ending: if you learned anything new about the user (role, preferences), received corrections (feedback), discovered project context (decisions, deadlines), or found external references — save them as memory files in .github/memory/ and update MEMORY.md. Use frontmatter with name, description, type fields. If nothing new was learned this session, you may end."
  }
}'
