---
name: harnesscp-gates
description: >
  Design quality gates, validation hooks, feedback loops, and self-evaluation
  patterns for VS Code Copilot harnesses. Use this skill whenever you need to
  add automated checks, catch drift, prevent regressions, set up pre-commit or
  post-edit validation, create self-correcting workflows, or design multi-layer
  quality systems. Trigger on: "add quality checks", "auto-test", "catch drift",
  "validate automatically", "quality gate", "feedback loop", or any request about
  automated validation.
argument-hint: "what quality problem to solve"
user-invocable: true
---

# HarnessCP Gates

Design quality gates and feedback loops that catch mistakes at every checkpoint — from individual edits to end-of-session health checks. Gates make quality automatic rather than aspirational.

## Why gates matter

Without gates, quality depends on the model remembering every rule and the user reviewing every change. Gates catch mistakes the moment they happen, before they compound. Each gate failure is a learning opportunity that improves the harness.

## Gate Layers

| Layer | When | Speed target | Scope | Copilot mechanism |
|-------|------|-------------|-------|-------------------|
| **Post-edit** | After every file change | < 1 sec | Single file | PostToolUse hook |
| **Pre-action** | Before risky operations | < 1 sec | Single action | PreToolUse hook |
| **Subagent** | When delegating/completing | < 5 sec | Agent scope | SubagentStart/Stop hooks |
| **Pre-compact** | Before context trimming | < 2 sec | Session state | PreCompact hook |
| **End-of-session** | When session ends | < 10 sec | Full project | Stop hook |
| **Pre-commit** | Before git commit | < 10 sec | Changed files | PreToolUse on runCommand |
| **CI pipeline** | After push | < 10 min | Full project | External (GitHub Actions) |

## What Each Gate Should Check

### Post-edit gates (PostToolUse)
- Format the edited file (Prettier, ruff, rustfmt, gofmt)
- Validate schema files (JSON, YAML, OpenAPI)
- Check for security anti-patterns (eval, innerHTML, SQL concatenation)
- Verify import/export consistency
- Run the nearest test file if one exists

### Pre-action gates (PreToolUse)
- Block destructive commands (rm -rf, force push, DROP TABLE)
- Block secret writes (API keys, private keys, passwords)
- Prompt for shared-state operations (git push, npm publish, deploy)
- Validate file paths are within workspace

### Subagent gates (SubagentStart/Stop)
- **Start**: Verify the subagent has appropriate tool restrictions for its task
- **Start**: Log which agent was spawned and why
- **Stop**: Validate output meets quality criteria before accepting
- **Stop**: Check for unintended side effects (files created/modified outside scope)

### Pre-compact gates (PreCompact)
- Export critical session state to a temporary file
- Save any unsaved memory candidates
- Log context size before and after compaction

### End-of-session gates (Stop)
- Check for uncommitted changes that should be committed
- Verify harness files haven't drifted (instructions stale, hooks broken)
- Prompt memory capture for new learnings
- Report session summary (files changed, tests passed/failed)

## Step 1: Assess Current Gate Coverage

For each gate layer, check what exists:

```bash
echo "=== PostToolUse gates ==="
grep -l "PostToolUse" .github/hooks/*.json 2>/dev/null || echo "None"

echo "=== PreToolUse gates ==="
grep -l "PreToolUse" .github/hooks/*.json 2>/dev/null || echo "None"

echo "=== SubagentStart/Stop gates ==="
grep -l "Subagent" .github/hooks/*.json 2>/dev/null || echo "None"

echo "=== PreCompact gates ==="
grep -l "PreCompact" .github/hooks/*.json 2>/dev/null || echo "None"

echo "=== Stop gates ==="
grep -l '"Stop"' .github/hooks/*.json 2>/dev/null || echo "None"
```

Map coverage to a heat map:

| Layer | Exists? | Quality |
|-------|---------|---------|
| Post-edit | Yes/No | None / Basic / Solid |
| Pre-action | Yes/No | None / Basic / Solid |
| Subagent | Yes/No | None / Basic / Solid |
| Pre-compact | Yes/No | None / Basic / Solid |
| End-of-session | Yes/No | None / Basic / Solid |

## Step 2: Design Gate Priority

Not every project needs every gate. Prioritize by impact:

### Minimum viable gates (every project)
1. **Post-edit formatting** — prevents style drift
2. **Pre-action command gate** — prevents catastrophic mistakes
3. **End-of-session memory capture** — preserves learnings

### Recommended additions
4. **Secret scanner** — prevents credential leaks
5. **Post-edit linting** — catches bugs early
6. **End-of-session drift check** — catches harness staleness

### Advanced gates (complex projects)
7. **Subagent validation** — ensures delegation quality
8. **Pre-compact state preservation** — prevents context loss
9. **Test-on-change** — catches regressions immediately

## Step 3: Implement the Feedback Loop

Every gate failure should trigger a feedback loop:

```
Gate failure detected
    ↓
Diagnose: What went wrong? (model output, script stderr, exit code)
    ↓
Fix: Is this a one-time mistake or a pattern?
    ↓
    ├─ One-time → Model fixes the immediate issue
    └─ Pattern → Update harness (add instruction, improve gate, add memory)
    ↓
Verify: Re-run the gate to confirm the fix works
    ↓
Log: What changed, why, and what it prevents
```

### Making gates provide good feedback

Every gate failure must answer three questions:
1. **What failed?** — "Lint error in src/main.ts:42"
2. **Why it matters?** — "Unused import increases bundle size"
3. **How to fix?** — "Remove the import or use it"

Bad gate output: `exit 2` with no message.
Good gate output: JSON with `additionalContext` explaining the issue and fix.

### Preventing gate fatigue

- Gate failures should be rare, not routine
- If a gate fires on >20% of operations, it's either too sensitive or the instructions need updating
- Track gate fire rate: if it's always blocking the same pattern, add an instruction to prevent it upstream

## Step 4: Design Self-Evaluation Patterns

For high-stakes outputs, add evaluation gates:

### The eval-then-fix pattern
1. Agent produces output (code, config, documentation)
2. A gate or second agent evaluates against criteria
3. If evaluation fails, specific corrections feed back
4. Agent fixes and re-runs the gate
5. Repeat until pass or retry limit

### Assertion-based validation
Define "good" as executable checks:

```bash
# Every API endpoint has a test
for route in $(grep -r 'router\.' src/routes/ -l); do
  test_file=$(echo "$route" | sed 's/src/tests/' | sed 's/\.ts/.test.ts/')
  [ ! -f "$test_file" ] && echo "Missing test: $test_file"
done

# No file exceeds 300 lines
find src/ -name "*.ts" -exec sh -c 'lines=$(wc -l < "$1"); [ "$lines" -gt 300 ] && echo "Too long ($lines lines): $1"' _ {} \;

# All JSON configs parse
for f in .github/hooks/*.json; do
  jq . "$f" > /dev/null 2>&1 || echo "Invalid JSON: $f"
done
```

## Step 5: The Drift Detection Gate

A critical end-of-session gate that catches harness staleness:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_ACTIVE" = "true" ] && echo '{}' && exit 0

WARNINGS=""

# Check instructions freshness (if git is available)
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
  INSTRUCTIONS=".github/copilot-instructions.md"
  if [ -f "$INSTRUCTIONS" ]; then
    LAST_MODIFIED=$(git log -1 --format=%ct -- "$INSTRUCTIONS" 2>/dev/null || echo 0)
    LAST_CODE_CHANGE=$(git log -1 --format=%ct 2>/dev/null || echo 0)
    DAYS_STALE=$(( (LAST_CODE_CHANGE - LAST_MODIFIED) / 86400 ))
    [ "$DAYS_STALE" -gt 30 ] && WARNINGS="$WARNINGS\n- copilot-instructions.md hasn't been updated in ${DAYS_STALE} days"
  fi
fi

# Check memory index sync
if [ -d ".github/memory" ]; then
  MEMORY_FILES=$(find .github/memory -name "*.md" ! -name "MEMORY.md" | wc -l)
  INDEX_ENTRIES=$(grep -c '\.md)' .github/memory/MEMORY.md 2>/dev/null || echo 0)
  [ "$MEMORY_FILES" -ne "$INDEX_ENTRIES" ] && WARNINGS="$WARNINGS\n- Memory files ($MEMORY_FILES) don't match index entries ($INDEX_ENTRIES)"
fi

# Check hook scripts are executable
for script in hooks/*.sh; do
  [ -f "$script" ] && [ ! -x "$script" ] && WARNINGS="$WARNINGS\n- Hook script not executable: $script"
done

# Check JSON validity of hook definitions
for json in .github/hooks/*.json; do
  [ -f "$json" ] && ! jq . "$json" > /dev/null 2>&1 && WARNINGS="$WARNINGS\n- Invalid JSON: $json"
done

if [ -n "$WARNINGS" ]; then
  jq -n --arg warnings "$WARNINGS" '{
    "hookSpecificOutput": {
      "additionalContext": ("Harness drift detected:" + $warnings + "\nConsider fixing these issues before your next session.")
    }
  }'
else
  echo '{}'
fi
```

## Anti-Patterns

- **Too strict**: Gates block so often that they're bypassed. Set achievable thresholds.
- **Too loose**: Issues reach production despite gates. Audit: for each incident, ask "which gate should have caught this?"
- **Too slow**: Gates >2 seconds interrupt flow. Move slow checks to end-of-session or CI.
- **No feedback**: Gate fails with a cryptic exit code. Always explain what, why, and how to fix.
- **No feedback loop**: Gate catches the same issue repeatedly without improving the harness. Each recurring failure should result in a harness update.
- **Layering without purpose**: Adding gates at every layer for the same check. One well-placed gate beats three redundant ones.
