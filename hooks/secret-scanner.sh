#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: block file writes that contain secrets or credentials.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only check file write operations
if [[ "$TOOL_NAME" != "editFiles" && "$TOOL_NAME" != "createFile" ]]; then
  echo '{}'
  exit 0
fi

CONTENT=$(echo "$INPUT" | jq -r '.tool_input | tostring')

# Check for common secret patterns
FOUND=""

# AWS access keys
echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}' && FOUND="$FOUND AWS access key,"

# OpenAI/Anthropic API keys
echo "$CONTENT" | grep -qE 'sk-[a-zA-Z0-9]{20,}' && FOUND="$FOUND API key (sk-*),"

# Private keys
echo "$CONTENT" | grep -qE '-----BEGIN.*PRIVATE KEY-----' && FOUND="$FOUND private key,"

# Hardcoded passwords (common patterns)
echo "$CONTENT" | grep -qE 'password\s*[:=]\s*["\x27][^"\x27]{8,}' && FOUND="$FOUND hardcoded password,"

# GitHub tokens
echo "$CONTENT" | grep -qE 'ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}' && FOUND="$FOUND GitHub token,"

if [ -n "$FOUND" ]; then
  jq -n --arg found "$FOUND" '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": ("Potential secrets detected:" + $found + " Remove credentials before writing. Use environment variables or a secrets manager instead.")
    }
  }'
else
  echo '{}'
fi
