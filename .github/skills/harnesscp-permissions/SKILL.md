---
name: harnesscp-permissions
description: >
  Configure permission boundaries for VS Code Copilot — agent tool restrictions,
  PreToolUse permission hooks, and safety gates. Use this skill whenever someone
  needs to set up what tools each agent can access, is getting too many permission
  prompts, has overly permissive agents, or wants to restrict dangerous operations.
  Trigger on: "fix permissions", "too many prompts", "restrict agent", "block
  dangerous commands", "permission setup", or any request about what the model
  can do without asking.
argument-hint: "what permission problem to solve"
user-invocable: true
---

# HarnessCP Permissions

Configure what the model can do autonomously vs. what requires confirmation. In VS Code Copilot, permissions are distributed across two mechanisms: **agent tool restrictions** and **PreToolUse hooks**. Together they provide layered security.

## Why permissions matter

Too permissive: the model runs destructive commands, pushes broken code, or modifies production configs without asking. Too restrictive: every action requires approval, killing flow and making the model useless for autonomous work.

## How Copilot permissions differ from Claude Code

Claude Code uses a central `settings.json` with `allow`/`deny` patterns. Copilot distributes permissions differently:

| Mechanism | Scope | Controls |
|-----------|-------|----------|
| **Agent tool restrictions** | Per-agent | Which tools an agent can access at all |
| **PreToolUse hooks** | Global or per-agent | Dynamic allow/deny/ask decisions before any tool executes |
| **VS Code settings** | Global | `chat.tools.edits.autoApprove` and similar |

This is more powerful (different agents get different permissions) but harder to audit (no single file shows everything).

## The Blast Radius Principle

Use risk level to determine the permission approach:

| Blast Radius | Examples | Permission |
|-------------|----------|-----------|
| Local, reversible | Read files, search code, run tests | Auto-allow (include in agent tools) |
| Local, hard to reverse | Delete files, overwrite uncommitted changes | Prompt (PreToolUse hook with `ask`) |
| Shared state | Git push, deploy, publish packages | Always prompt or block |
| External systems | API calls, send messages, modify infra | Always prompt or block |

## Step 1: Detect Project Tooling

Read build manifests to understand what tools are available:

```bash
# What package manager?
ls package.json Cargo.toml pyproject.toml go.mod Gemfile pom.xml 2>/dev/null

# What scripts/tasks exist?
cat package.json | jq '.scripts' 2>/dev/null
cat Makefile 2>/dev/null | grep '^[a-zA-Z].*:' | head -20
```

Build a list of tools the project uses: test runners, linters, formatters, build tools, deployment tools.

## Step 2: Check Current Permissions

### Agent tool restrictions

Check all `.github/agents/*.agent.md` files for their `tools` field:

```bash
# List all agents and their tool restrictions
for f in .github/agents/*.agent.md; do
  echo "=== $(basename $f) ==="
  head -20 "$f" | grep -A 50 'tools:'
done
```

An agent without a `tools` field has access to everything — this is the default and usually too permissive.

### PreToolUse hooks

Check for existing permission hooks:

```bash
# Find all PreToolUse hook definitions
grep -r "PreToolUse" .github/hooks/ 2>/dev/null
```

### VS Code settings

Check workspace settings for auto-approval:

```bash
cat .vscode/settings.json 2>/dev/null | jq '.["chat.tools.edits.autoApprove"]'
```

## Step 3: Design Agent Tool Sets

For each agent, define the minimum tools needed:

### Read-only agent (code review, analysis)
```yaml
tools:
  - readFile
  - listFiles
  - search/codebase
  - search/workspace
```

### Build/test agent
```yaml
tools:
  - readFile
  - listFiles
  - search/codebase
  - runCommand
  - editFiles
```

### Full development agent (default)
```yaml
tools:
  - readFile
  - editFiles
  - listFiles
  - search/codebase
  - search/workspace
  - runCommand
  - web/fetch
```

### Deploy agent (restricted, always confirm)
```yaml
tools:
  - readFile
  - listFiles
  - runCommand
```

The principle: each agent gets only the tools it needs. A code review agent doesn't need `editFiles`. A deploy agent doesn't need `web/fetch`.

## Step 4: Design PreToolUse Permission Hooks

For operations that need dynamic decisions (not just tool-level allow/deny), create PreToolUse hooks.

### Command gate hook

Create `.github/hooks/command-gate.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./hooks/command-gate.sh",
        "timeout": 5
      }
    ]
  }
}
```

The companion script checks the tool input against dangerous patterns and returns a permission decision.

### Permission decision format

PreToolUse hooks return structured decisions:

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Why this decision was made"
  }
}
```

- `allow` — proceed without prompting
- `deny` — block the operation, show reason
- `ask` — prompt the user for confirmation

When multiple hooks run, the most restrictive wins: deny > ask > allow.

### Common permission patterns

**Block destructive commands:**
```bash
# In command-gate.sh: check for dangerous patterns
DANGEROUS_PATTERNS='rm -rf|git push.*--force|git reset --hard|DROP TABLE|DELETE FROM|kubectl delete|terraform destroy'
```

**Block secret writes:**
```bash
# In secret-scanner.sh: check file content for secrets
SECRET_PATTERNS='AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{48}|-----BEGIN.*PRIVATE KEY-----|password\s*=\s*["\x27][^"\x27]+'
```

**Allow safe reads:**
```bash
# If tool_name is readFile, listFiles, or search — always allow
SAFE_TOOLS='readFile|listFiles|search'
```

## Step 5: Write and Verify

### Apply agent tool restrictions

For each agent file, add or update the `tools` field in YAML frontmatter.

### Create hook scripts

Write each permission hook script following the standard pattern:
1. Read JSON from stdin
2. Extract `tool_name` and `tool_input`
3. Check against patterns
4. Output JSON permission decision
5. Exit 0 for decisions, exit 2 for hard blocks

### Test hooks independently

```bash
# Test command gate with a dangerous input
echo '{"tool_name": "runCommand", "tool_input": {"command": "rm -rf /"}}' | ./hooks/command-gate.sh

# Test with a safe input
echo '{"tool_name": "readFile", "tool_input": {"path": "README.md"}}' | ./hooks/command-gate.sh
```

### Audit the full permission surface

After configuration, list all permissions:

```bash
echo "=== Agent Tool Restrictions ==="
for f in .github/agents/*.agent.md; do
  echo "$(basename $f .agent.md):"
  grep -A 20 '^tools:' "$f" | head -20
  echo
done

echo "=== PreToolUse Hooks ==="
grep -l "PreToolUse" .github/hooks/*.json 2>/dev/null

echo "=== VS Code Settings ==="
cat .vscode/settings.json 2>/dev/null | jq 'with_entries(select(.key | startswith("chat.tools")))'
```

This is the closest Copilot gets to a single permission view. The audit skill automates this.

## Anti-Patterns

- **No tool restrictions on agents**: Every agent can do everything. Add `tools` to every agent.
- **Overly broad PreToolUse hooks**: Checking every tool invocation when you only care about `runCommand`. Use tool_name filtering in your script.
- **Blocking on warnings**: Use `deny` sparingly. Most issues should use `ask` to let the user decide.
- **Permission fatigue**: Too many `ask` prompts and users stop reading them. Reserve prompts for genuinely risky operations.
- **No audit trail**: Permission decisions aren't logged. Consider a PostToolUse hook that logs approved dangerous operations.
- **Forgetting VS Code settings**: Agent tool restrictions and hooks are meaningless if `chat.tools.edits.autoApprove: true` bypasses everything at the VS Code level.
