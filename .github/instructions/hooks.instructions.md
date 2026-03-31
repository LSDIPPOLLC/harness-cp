---
applyTo: ".github/hooks/**,hooks/**"
---

# Hook File Conventions

When editing hook definitions (JSON) or companion scripts (shell):

## JSON definitions (.github/hooks/*.json)
- One hook per file, organized by lifecycle event
- Must include `type`, `command`, and `timeout` fields
- Event names are PascalCase: SessionStart, PreToolUse, PostToolUse, Stop, etc.
- Reference companion scripts with relative paths from project root

## Shell scripts (hooks/*.sh)
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Read JSON from stdin: `INPUT=$(cat)`
- Extract fields with jq: `TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')`
- Output JSON to stdout
- Exit 0 for success, exit 2 to block
- Always handle missing/malformed input gracefully (default to `echo '{}' && exit 0`)
- Check `stop_hook_active` in Stop hooks to prevent infinite loops
