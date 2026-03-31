#!/usr/bin/env bash
set -euo pipefail

# Stop hook: end-of-session harness health check.
# Detects stale instructions, memory sync issues, broken hooks.

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  echo '{}'
  exit 0
fi

WARNINGS=""

# Check instructions freshness
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
  INSTRUCTIONS=".github/copilot-instructions.md"
  if [ -f "$INSTRUCTIONS" ]; then
    LAST_MODIFIED=$(git log -1 --format=%ct -- "$INSTRUCTIONS" 2>/dev/null || echo 0)
    LAST_CODE_CHANGE=$(git log -1 --format=%ct 2>/dev/null || echo 0)
    if [ "$LAST_MODIFIED" -gt 0 ] && [ "$LAST_CODE_CHANGE" -gt 0 ]; then
      DAYS_STALE=$(( (LAST_CODE_CHANGE - LAST_MODIFIED) / 86400 ))
      [ "$DAYS_STALE" -gt 30 ] && WARNINGS="$WARNINGS\n- copilot-instructions.md hasn't been updated in ${DAYS_STALE} days"
    fi
  else
    WARNINGS="$WARNINGS\n- No copilot-instructions.md found"
  fi
fi

# Check memory index sync
if [ -d ".github/memory" ]; then
  MEMORY_FILES=$(find .github/memory -name "*.md" ! -name "MEMORY.md" 2>/dev/null | wc -l)
  INDEX_ENTRIES=$(grep -c '\.md)' .github/memory/MEMORY.md 2>/dev/null || echo 0)
  if [ "$MEMORY_FILES" -ne "$INDEX_ENTRIES" ]; then
    WARNINGS="$WARNINGS\n- Memory files ($MEMORY_FILES) don't match index entries ($INDEX_ENTRIES)"
  fi
fi

# Check hook scripts are executable
for script in hooks/*.sh; do
  [ -f "$script" ] && [ ! -x "$script" ] && WARNINGS="$WARNINGS\n- Hook not executable: $script"
done

# Validate hook JSON
for json in .github/hooks/*.json; do
  [ -f "$json" ] && ! jq . "$json" > /dev/null 2>&1 && WARNINGS="$WARNINGS\n- Invalid JSON: $json"
done

# Check for conditional instruction files without applyTo
for inst in .github/instructions/*.instructions.md; do
  if [ -f "$inst" ] && ! grep -q 'applyTo:' "$inst"; then
    WARNINGS="$WARNINGS\n- Conditional instruction without applyTo: $inst"
  fi
done

if [ -n "$WARNINGS" ]; then
  jq -n --arg warnings "$WARNINGS" '{
    "hookSpecificOutput": {
      "additionalContext": ("Harness drift detected:" + $warnings + "\nConsider addressing these before your next session.")
    }
  }'
else
  echo '{}'
fi
