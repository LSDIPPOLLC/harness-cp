#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: block dangerous commands, prompt for risky ones.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only check command execution
if [[ "$TOOL_NAME" != "runCommand" ]]; then
  echo '{}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block destructive commands
if echo "$COMMAND" | grep -qE 'rm -rf /|rm -rf \.|git push.*--force|git reset --hard|DROP TABLE|DELETE FROM.*WHERE 1|kubectl delete namespace|terraform destroy'; then
  jq -n --arg cmd "$COMMAND" '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": ("Dangerous command blocked: " + $cmd + ". This command could cause irreversible damage.")
    }
  }'
  exit 0
fi

# Prompt for shared-state commands
if echo "$COMMAND" | grep -qE 'git push|npm publish|docker push|terraform apply|kubectl apply|helm install|helm upgrade'; then
  jq -n --arg cmd "$COMMAND" '{
    "hookSpecificOutput": {
      "permissionDecision": "ask",
      "permissionDecisionReason": ("This command affects shared state: " + $cmd)
    }
  }'
  exit 0
fi

# Allow everything else
echo '{}'
