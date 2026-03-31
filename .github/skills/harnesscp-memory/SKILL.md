---
name: harnesscp-memory
description: >
  Design, set up, audit, and maintain a project's file-based memory system for
  VS Code Copilot. Use this skill whenever someone needs to create a memory
  structure, organize existing memories, audit for staleness or gaps, understand
  what should be memory vs. instructions vs. a skill, or fix broken memory
  indexing. Trigger on: "set up memory", "organize memories", "audit my memories",
  "memory system", "copilot keeps forgetting", "remember across sessions",
  "MEMORY.md", or any request about persistent cross-session state. Also trigger
  when someone says "I already told you this" — that's a missing memory.
argument-hint: "set up, audit, or describe what to remember"
user-invocable: true
---

# HarnessCP Memory

Design and maintain the memory system that lets the model retain knowledge across conversations. Memory transforms a stateless tool into a collaborative partner that learns your project over time.

## Why memory matters (and why it's harder in Copilot)

Without memory, every conversation starts from zero. The user re-explains their role, re-corrects the same mistakes, re-describes external systems.

**VS Code Copilot has no built-in memory system.** This is the single biggest gap compared to Claude Code. HarnessCP solves this with a convention-based approach using files, hooks, and a curator agent. It works well when the model follows instructions consistently — which Claude does — but it's convention-enforced, not platform-enforced.

The memory system has three components:
1. **Storage** — `.github/memory/` directory with typed files and `MEMORY.md` index
2. **Hooks** — SessionStart injects memories, Stop prompts capture
3. **Curator agent** — Dedicated agent for memory file operations

## Memory Types

| Type | What it stores | Example |
|------|---------------|---------|
| **user** | Who the user is, their role, preferences, expertise | "Senior backend engineer, prefers terse output" |
| **feedback** | Corrections AND confirmations of approach | "Don't mock the DB in integration tests — use real DB" |
| **project** | Ongoing work, decisions, status, deadlines | "Auth rewrite driven by compliance, not tech debt" |
| **reference** | Pointers to external systems and resources | "Pipeline bugs tracked in Linear project INGEST" |

## Step 1: Check Current State

Look for existing memory infrastructure:

```
.github/memory/
  MEMORY.md          # Index file
  *.md               # Individual memory files
```

Also check for hook definitions:
- `.github/hooks/memory-inject.json` — SessionStart hook
- `.github/hooks/memory-capture.json` — Stop hook

And the curator agent:
- `.github/agents/memory-curator.agent.md`

If memory exists, audit it (Step 4). If not, create the full system.

## Step 2: Create Memory Structure

### Directory and index

```bash
mkdir -p .github/memory
```

MEMORY.md format — this is an index, not content:

```markdown
# Memory Index

## User
- [User Role](user_role.md) — Senior backend eng, prefers concise output

## Feedback
- [Testing Approach](feedback_testing.md) — Use real DB, never mock in integration tests

## Project
- [Auth Rewrite](project_auth_rewrite.md) — Compliance-driven, deadline March 2026

## References
- [Bug Tracker](reference_bug_tracker.md) — Linear project INGEST for pipeline bugs
```

Rules for MEMORY.md:
- One line per memory, under 150 characters
- Organized by type, not chronologically
- No content in the index — just pointers and one-line hooks
- Keep under 200 lines

### Memory file format

Each memory is a separate .md file with frontmatter:

```markdown
---
name: descriptive-name
description: One-line description used to decide relevance in future conversations
type: user|feedback|project|reference
---

Content here. For feedback and project types, structure as:

Rule or fact statement.

**Why:** The reason behind it.

**How to apply:** When and where this guidance kicks in.
```

### Naming conventions

- Prefix with type: `user_role.md`, `feedback_testing.md`, `project_auth.md`, `reference_linear.md`
- Descriptive names, not dates: `feedback_db_mocking.md` not `feedback_2026-03-15.md`
- Short but specific enough to distinguish

### Reference in copilot-instructions.md

Add this section to `copilot-instructions.md` (or verify it exists):

```markdown
## Memory

This project uses a file-based memory system at `.github/memory/`.
The index is `MEMORY.md`. Read it at session start to load persistent context.
When you learn something that should persist across sessions, write a memory
file and update the index. Memory types: user, feedback, project, reference.
```

This tells the model about the memory system on every session.

## Step 3: Set Up Memory Hooks

### SessionStart hook (memory injection)

Create `.github/hooks/memory-inject.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "./hooks/memory-inject.sh",
        "timeout": 10
      }
    ]
  }
}
```

Create `hooks/memory-inject.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

MEMORY_DIR=".github/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

# If no memory index exists, exit cleanly
if [ ! -f "$MEMORY_INDEX" ]; then
  echo '{}'
  exit 0
fi

# Read the memory index and inject as additional context
MEMORY_CONTENT=$(cat "$MEMORY_INDEX")

# Output JSON with memory content as additional context
jq -n --arg content "$MEMORY_CONTENT" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Memory system active. Memory index:\n\n" + $content + "\n\nRead individual memory files from .github/memory/ when relevant to the current task.")
  }
}'
```

### Stop hook (memory capture)

Create `.github/hooks/memory-capture.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "./hooks/memory-capture.sh",
        "timeout": 5
      }
    ]
  }
}
```

Create `hooks/memory-capture.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

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
    "reason": "Before ending: if you learned anything new about the user, received corrections, discovered project context, or found external references that should persist across sessions — save them as memory files in .github/memory/ and update MEMORY.md. If nothing new was learned, you can end the session."
  }
}'
```

Make scripts executable:
```bash
chmod +x hooks/memory-inject.sh hooks/memory-capture.sh
```

## Step 4: Set Up Curator Agent

Create `.github/agents/memory-curator.agent.md`:

```yaml
---
name: memory-curator
description: "Curate the project memory system — read, write, organize, and audit memory files in .github/memory/"
tools:
  - readFile
  - editFiles
  - listFiles
  - search/codebase
model: ["claude-sonnet-4-6", "claude-sonnet-4-5"]
agents: []
---
```

```markdown
You are the memory curator for this project. Your sole job is managing the file-based memory system in `.github/memory/`.

## What you do
- Read and summarize existing memories when asked
- Create new memory files with proper frontmatter (name, description, type)
- Update stale memories with current information
- Delete memories that are no longer relevant
- Keep MEMORY.md index in sync with actual files
- Audit memory quality: frontmatter completeness, description specificity, staleness

## Memory types
- **user** — who the user is, preferences, expertise
- **feedback** — corrections and confirmations of approach (include Why and How to apply)
- **project** — ongoing work, decisions, deadlines (use absolute dates)
- **reference** — pointers to external systems

## Rules
- Never store code patterns, architecture, or file paths — these belong in instructions or are discovered at runtime
- Never store git history or debugging solutions
- Always use absolute dates, never relative ("Thursday" → "2026-03-05")
- One memory per file, prefixed by type: `user_role.md`, `feedback_testing.md`
- Keep MEMORY.md entries under 150 characters each
- When updating, modify in place — don't create duplicates
```

## Step 5: Seed Initial Memories

For a new project, create seed memories based on what you learn during setup:

**Always worth seeding:**
- `user_role.md` — Who is the user, what's their expertise level
- `reference_*` — Any external systems mentioned (issue tracker, docs, deployment)

**Seed if discovered:**
- `project_*` — Active initiatives, deadlines, decisions
- `feedback_*` — Stated preferences about how to work

**Don't seed speculatively.** Only create memories for things you have evidence of.

## Step 6: Audit Existing Memories

If memories already exist, check each one:

### Quality checklist

For each memory file:
- [ ] Has complete frontmatter (name, description, type)
- [ ] Description is specific enough to judge relevance
- [ ] Content is still accurate (not stale)
- [ ] Not duplicated by another memory
- [ ] Belongs in memory (not in instructions or code)

### Common problems

| Problem | Fix |
|---------|-----|
| Missing frontmatter | Add name, description, type |
| Vague description | Rewrite: "user preference" → "prefers single PR for refactors, confirmed 2026-03" |
| Stale content | Update or delete — stale memories teach wrong things |
| Duplicate memories | Merge into one, delete the other, update index |
| Code patterns as memory | Delete — belongs in instructions or discovered from code |
| Conversation-specific notes | Delete — these should be tasks, not memories |

### Index sync check

```bash
# Memory files that exist
find .github/memory -name "*.md" ! -name "MEMORY.md" | sort

# Compare against entries in MEMORY.md
grep -oP '\(([^)]+\.md)\)' .github/memory/MEMORY.md | tr -d '()' | sort
```

Fix mismatches — orphaned files or broken links.

## What Belongs Where

| Information | Where it goes | Why |
|------------|--------------|-----|
| Build commands, code style | copilot-instructions.md | Needed every session |
| React patterns, test conventions | Conditional *.instructions.md | Domain-specific, glob-scoped |
| User's role, expertise | Memory (user) | Relevant but not always |
| "Don't do X" corrections | Memory (feedback) | Must persist, not always relevant |
| Active sprint/deadline | Memory (project) | Time-bound, cross-session |
| External system URLs | Memory (reference) | Rarely needed, easy to forget |
| Detailed workflow steps | Skill or prompt file | On-demand, not always relevant |
| File paths, function names | Nothing — discover at runtime | Changes too fast |
| Git history | Nothing — use git log | Git is authoritative |

## Anti-Patterns

- **Hoarding**: Saving everything "just in case." Each memory takes index space and may be loaded unnecessarily.
- **Journaling**: Using memories as a changelog. "March 15: fixed auth bug" is git history, not memory.
- **Duplicating instructions**: If it's in copilot-instructions.md, don't also put it in memory.
- **Storing code**: Memory is for human context, not code patterns.
- **Relative dates**: "Next Thursday" is meaningless in a future session. Always use absolute dates.
- **No hook setup**: The memory system without hooks requires the user to manually tell the model to read/write memories. Hooks make it automatic.
