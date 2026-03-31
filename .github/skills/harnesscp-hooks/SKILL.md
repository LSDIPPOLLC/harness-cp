---
name: harnesscp-hooks
description: >
  Design, implement, debug, and manage VS Code Copilot hooks — automated behaviors
  that fire at key lifecycle points during agent sessions. Use this skill whenever
  someone wants to add auto-formatting, auto-linting, safety gates, test-on-change,
  session-start context injection, or end-of-session health checks. Trigger on:
  "add a hook", "auto-format", "auto-lint", "run tests automatically", "block
  dangerous commands", "hook not firing", or any request about automated agent
  behaviors.
argument-hint: "what behavior to automate"
user-invocable: true
---

# HarnessCP Hooks

Design and implement hooks — automated behaviors that fire at key lifecycle points during agent sessions. Hooks enforce quality without requiring the user to remember to ask.

## Why hooks matter

Without hooks, quality depends entirely on the model remembering instructions. Hooks make quality automatic: every edit gets formatted, every dangerous command gets blocked, every session ends with a health check. They're the difference between "please format your code" and code that's always formatted.

## The 8 Lifecycle Events

VS Code Copilot provides 8 hook points — significantly more than Claude Code's 3:

| Event | When it fires | Best for |
|-------|--------------|----------|
| **SessionStart** | New session begins | Context injection, resource initialization, state validation |
| **UserPromptSubmit** | User submits a message | Prompt auditing, context injection based on prompt content |
| **PreToolUse** | Before any tool executes | Permission gates, dangerous operation blocking, input validation |
| **PostToolUse** | After a tool completes | Auto-format, auto-lint, test running, result validation |
| **PreCompact** | Before context compaction | Memory preservation, state export |
| **SubagentStart** | Subagent is spawned | Validate subagent has appropriate tools, initialize resources |
| **SubagentStop** | Subagent completes | Validate output quality, aggregate results, cleanup |
| **Stop** | Session ends | Health checks, memory capture, drift detection, reports |

## Hook Configuration

### File locations

- **Workspace hooks**: `.github/hooks/*.json`
- **User hooks**: `~/.copilot/hooks/`
- **Agent-scoped hooks**: `hooks` field in `.agent.md` frontmatter

### JSON format

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "./hooks/auto-format.sh",
        "linux": "./hooks/auto-format.sh",
        "osx": "./hooks/auto-format-mac.sh",
        "windows": "powershell -File hooks\\auto-format.ps1",
        "timeout": 10,
        "env": { "CUSTOM_VAR": "value" }
      }
    ]
  }
}
```

### Hook I/O

**Input** (JSON via stdin):
```json
{
  "timestamp": "2026-03-31T10:30:00.000Z",
  "cwd": "/path/to/workspace",
  "sessionId": "session-id",
  "hookEventName": "PostToolUse",
  "tool_name": "editFiles",
  "tool_input": { "files": ["src/main.ts"] },
  "tool_response": "File edited successfully"
}
```

**Output** (JSON via stdout):
```json
{
  "continue": true,
  "systemMessage": "Optional warning for the model",
  "hookSpecificOutput": {
    "additionalContext": "Context injected into the session"
  }
}
```

### Exit codes

- **0** — Success. Parse stdout as JSON.
- **2** — Block. Stop processing, show error to the model.
- **Other** — Warning. Log but continue processing.

## Step 1: Identify Hook Needs

Survey the project for automation opportunities:

| Question | If yes → Hook type |
|----------|-------------------|
| Does the project have a formatter? | PostToolUse auto-format |
| Does the project have a linter? | PostToolUse auto-lint |
| Are there destructive CLI commands to guard? | PreToolUse command gate |
| Are secrets a concern? | PreToolUse secret scanner |
| Is there a test suite? | PostToolUse test-on-change |
| Does the project need memory? | SessionStart + Stop hooks |
| Are subagents used? | SubagentStart/Stop validation |
| Is context budget a concern? | PreCompact memory preservation |

## Step 2: Implement Common Hook Patterns

### Auto-format on save

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only run after file edits
if [[ "$TOOL_NAME" != "editFiles" && "$TOOL_NAME" != "createFile" ]]; then
  echo '{}'
  exit 0
fi

# Extract edited file paths
FILES=$(echo "$INPUT" | jq -r '.tool_input.files[]? // .tool_input.path // ""')

for FILE in $FILES; do
  [ -z "$FILE" ] && continue
  case "$FILE" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
      npx prettier --write "$FILE" 2>/dev/null || true ;;
    *.py)
      ruff format "$FILE" 2>/dev/null || true ;;
    *.rs)
      rustfmt "$FILE" 2>/dev/null || true ;;
    *.go)
      gofmt -w "$FILE" 2>/dev/null || true ;;
  esac
done

echo '{}'
```

### Auto-lint on edit

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

if [[ "$TOOL_NAME" != "editFiles" ]]; then
  echo '{}'
  exit 0
fi

FILES=$(echo "$INPUT" | jq -r '.tool_input.files[]? // ""')
ISSUES=""

for FILE in $FILES; do
  [ -z "$FILE" ] && continue
  case "$FILE" in
    *.ts|*.tsx|*.js|*.jsx)
      RESULT=$(npx eslint "$FILE" 2>/dev/null || true)
      [ -n "$RESULT" ] && ISSUES="$ISSUES\n$RESULT" ;;
    *.py)
      RESULT=$(ruff check "$FILE" 2>/dev/null || true)
      [ -n "$RESULT" ] && ISSUES="$ISSUES\n$RESULT" ;;
  esac
done

if [ -n "$ISSUES" ]; then
  jq -n --arg issues "$ISSUES" '{
    "hookSpecificOutput": {
      "additionalContext": ("Lint issues found:\n" + $issues + "\nPlease fix these issues.")
    }
  }'
else
  echo '{}'
fi
```

### Secret scanner (PreToolUse)

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only check file writes
if [[ "$TOOL_NAME" != "editFiles" && "$TOOL_NAME" != "createFile" ]]; then
  echo '{}'
  exit 0
fi

CONTENT=$(echo "$INPUT" | jq -r '.tool_input | tostring')

# Check for common secret patterns
if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{48}|-----BEGIN.*PRIVATE KEY-----|password\s*=\s*["\x27][^"\x27]{8,}'; then
  jq -n '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": "Potential secret or credential detected in file content. Remove secrets before writing."
    }
  }'
else
  echo '{}'
fi
```

### Dangerous command gate (PreToolUse)

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only check command execution
if [[ "$TOOL_NAME" != "runCommand" ]]; then
  echo '{}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block destructive commands
if echo "$COMMAND" | grep -qE 'rm -rf /|rm -rf \.|git push.*--force|git reset --hard|DROP TABLE|DELETE FROM.*WHERE|kubectl delete|terraform destroy'; then
  jq -n --arg cmd "$COMMAND" '{
    "hookSpecificOutput": {
      "permissionDecision": "deny",
      "permissionDecisionReason": ("Dangerous command blocked: " + $cmd)
    }
  }'
# Prompt for risky commands
elif echo "$COMMAND" | grep -qE 'git push|npm publish|docker push|terraform apply'; then
  jq -n --arg cmd "$COMMAND" '{
    "hookSpecificOutput": {
      "permissionDecision": "ask",
      "permissionDecisionReason": ("This command affects shared state: " + $cmd)
    }
  }'
else
  echo '{}'
fi
```

## Step 3: Choose the Right Lifecycle Event

| Need | Event | Why |
|------|-------|-----|
| Format/lint after edits | PostToolUse | React to completed edits |
| Block dangerous operations | PreToolUse | Prevent before execution |
| Inject project context | SessionStart | Available from the start |
| Capture memories | Stop | Last chance before session ends |
| Validate subagent permissions | SubagentStart | Before subagent runs |
| Quality-check subagent output | SubagentStop | Before results used |
| Preserve state before compaction | PreCompact | Save before context is trimmed |
| Inject context per-prompt | UserPromptSubmit | Tailored to what user asked |

## Step 4: Write, Test, Deploy

### Write the hook script
1. Start with `set -euo pipefail`
2. Read JSON from stdin with `INPUT=$(cat)`
3. Extract relevant fields with `jq`
4. Do the work (format, lint, check, etc.)
5. Output JSON to stdout
6. Exit 0 (success) or exit 2 (block)

### Test independently
```bash
# Test with sample input
echo '{"tool_name": "editFiles", "tool_input": {"files": ["src/main.ts"]}}' | ./hooks/auto-format.sh

# Test blocking
echo '{"tool_name": "runCommand", "tool_input": {"command": "rm -rf /"}}' | ./hooks/command-gate.sh
```

### Deploy
1. Save script to `hooks/`
2. Make executable: `chmod +x hooks/your-hook.sh`
3. Create JSON definition in `.github/hooks/`
4. Test in a Copilot session

## Step 5: Debug Hooks

When a hook isn't working:

1. **Check the script exists and is executable**: `ls -la hooks/your-hook.sh`
2. **Validate the JSON definition**: `cat .github/hooks/your-hook.json | jq .`
3. **Test the script directly**: pipe sample JSON and check output
4. **Check jq is installed**: `which jq`
5. **Check for stderr output**: redirect stderr to a file for debugging
6. **Verify the event name**: PascalCase in Copilot (`PostToolUse`), not camelCase

## Anti-Patterns

- **Slow hooks** (>2 sec): Kill flow. Keep hooks fast or use longer timeouts sparingly.
- **Noisy hooks**: Print warnings on every invocation and users learn to ignore them. Reserve output for actionable issues.
- **Blocking on style issues**: Use `deny` for security, `ask` for risky ops, and `additionalContext` for style feedback.
- **No error handling**: Always handle missing/malformed JSON input. Default to `echo '{}' && exit 0`.
- **Hardcoded paths**: Use the `cwd` field from stdin, not hardcoded paths.
- **Ignoring OS differences**: Use `linux`, `osx`, `windows` fields for cross-platform hooks.
- **Not testing hooks**: Every hook should be testable independently with `echo | ./hooks/script.sh`.
