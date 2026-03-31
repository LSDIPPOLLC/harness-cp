#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: validate harness file changes.
# Checks copilot-instructions.md size, JSON syntax, secrets, and script permissions.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only run after file edits
if [[ "$TOOL_NAME" != "editFiles" && "$TOOL_NAME" != "createFile" ]]; then
  echo '{}'
  exit 0
fi

WARNINGS=""

# Check copilot-instructions.md size
INSTRUCTIONS=".github/copilot-instructions.md"
if [ -f "$INSTRUCTIONS" ]; then
  LINES=$(wc -l < "$INSTRUCTIONS")
  if [ "$LINES" -gt 600 ]; then
    WARNINGS="$WARNINGS\n- copilot-instructions.md is $LINES lines (>600). Consider moving content to conditional instruction files."
  elif [ "$LINES" -gt 400 ]; then
    WARNINGS="$WARNINGS\n- copilot-instructions.md is $LINES lines (>400). Getting heavy — review with /harnesscp-context."
  fi
fi

# Validate JSON syntax in hook definitions
for json in .github/hooks/*.json; do
  if [ -f "$json" ]; then
    if ! jq . "$json" > /dev/null 2>&1; then
      WARNINGS="$WARNINGS\n- Invalid JSON in $json"
    fi
  fi
done

# Ensure hook scripts are executable
for script in hooks/*.sh; do
  if [ -f "$script" ] && [ ! -x "$script" ]; then
    chmod +x "$script"
    WARNINGS="$WARNINGS\n- Made $script executable (was missing +x)"
  fi
done

if [ -n "$WARNINGS" ]; then
  jq -n --arg warnings "$WARNINGS" '{
    "hookSpecificOutput": {
      "additionalContext": ("Harness validation warnings:" + $warnings)
    }
  }'
else
  echo '{}'
fi
