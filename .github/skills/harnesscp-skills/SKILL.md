---
name: harnesscp-skills
description: >
  Analyze a project's workflows and decompose them into a well-composed skill
  system — atomic skills, composed workflows, and routing entry points for VS Code
  Copilot. Use this skill whenever someone wants to identify what skills their
  project needs, design skill composition, analyze workflow gaps, or restructure
  an existing skill set. Trigger on: "what skills do I need", "skill decomposition",
  "design my skills", "too many skills", "skill overlap", "missing workflow",
  or any request about organizing reusable AI workflows.
argument-hint: "what workflows to analyze"
user-invocable: true
---

# HarnessCP Skills

Analyze a project's workflows and decompose them into a well-composed skill system. Skills are the reusable building blocks that make the model productive on your specific project.

## Why skill design matters

Without skills, every complex workflow requires re-explaining the steps, context, and constraints from scratch. Skills encode repeatable workflows so invoking `/deploy` always follows the same safe process, and the model auto-discovers the right skill when it recognizes a relevant task.

VS Code Copilot's skill system is more powerful than simple commands:
- **Auto-invocation**: Skills load automatically when the model determines they're relevant
- **Progressive loading**: Only the description is always loaded; full instructions load on demand
- **Companion files**: Skills can include scripts, templates, and examples alongside SKILL.md
- **Open standard**: Skills work across VS Code, Copilot CLI, and the coding agent

## Step 1: Discover Workflows

### Ask the user
"What are the 3-5 things you most frequently ask the model to help with?"

Common answers map to skill categories:
- "Write tests" → test-writer skill
- "Review my code" → code-review skill
- "Deploy to staging" → deploy skill
- "Fix this bug" → debug skill
- "Add a new API endpoint" → api-generator skill

### Analyze git history

```bash
# What kinds of work happen most? (commit message verbs)
git log --oneline -100 | sed 's/^[a-f0-9]* //' | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Most active file patterns (what gets edited together?)
git log --pretty=format: --name-only -50 | sort | uniq -c | sort -rn | head -20
```

### Audit existing skills

```bash
# List all current skills
for f in .github/skills/*/SKILL.md; do
  NAME=$(grep '^name:' "$f" | sed 's/name: *//')
  DESC=$(grep '^description:' "$f" | head -1 | sed 's/description: *//' | cut -c1-80)
  echo "$NAME — $DESC"
done
```

### Map common workflow patterns

| Pattern | Examples | Skill type |
|---------|----------|-----------|
| Build & Deploy | Build, test, push, verify | Composed workflow |
| Code Review | Read diff, check patterns, suggest fixes | Atomic skill |
| Generate | New component, endpoint, migration, test | Atomic skill per domain |
| Debug | Reproduce, trace, diagnose, fix | Composed workflow |
| Release | Version bump, changelog, tag, publish | Composed workflow |
| Document | API docs, README updates, architecture | Atomic skill |

## Step 2: Classify Candidates

For each candidate workflow, ask:

| Question | Yes → | No → |
|----------|-------|------|
| Multi-step with clear sequence? | Skill | Maybe just instructions |
| Recurring (weekly+)? | Skill | One-off prompt file |
| Needs specific context or constraints? | Skill | Generic instructions suffice |
| Benefits from structured steps? | Skill | Too simple for a skill |
| Shareable across team members? | Skill (in .github/skills/) | Personal prompt file |

### Skills vs. other mechanisms

| If it's... | Use |
|-----------|-----|
| A complex, multi-step workflow | Skill with SKILL.md |
| A simple, single-purpose task | Prompt file (*.prompt.md) |
| Always-relevant rules | copilot-instructions.md |
| Domain-specific conventions | Conditional *.instructions.md |
| A persona with tool restrictions | Agent (.agent.md) |

## Step 3: Design the Skill Map

### Atomic skills
Bounded scope, clear trigger, defined output. Each does one thing well.

```
test-writer     — writes tests for a given file/function
code-reviewer   — reviews code for patterns, bugs, performance
api-generator   — scaffolds a new API endpoint with validation/tests
component-gen   — scaffolds a new UI component with props/styles/tests
db-migrator     — creates and validates database migrations
```

### Composed workflows
Chains of atomic skills for multi-phase tasks.

```
deploy          — build → test → push → verify (orchestrates 4 steps)
feature-dev     — plan → implement → test → review (build loop)
release         — version-bump → changelog → tag → publish
```

### Entry points
Router that dispatches vague requests to specialists.

```
project-helper  — classifies intent, routes to the right skill
```

## Step 4: Write SKILL.md Files

### Frontmatter template

```yaml
---
name: skill-name
description: >
  What this skill does AND when to use it. This is how Copilot discovers
  the skill — be specific about triggers. Max 1024 characters.
argument-hint: "what input the skill expects"
user-invocable: true
---
```

### Body structure

```markdown
# Skill Name

One-line summary of what this skill does.

## Why this matters

Brief context on why this workflow needs a skill (2-3 sentences).

## Step 1: [First step]
...

## Step 2: [Next step]
...

## Step N: [Final step]
...

## Anti-Patterns

- **Pattern name**: What goes wrong and how to avoid it.
```

### Description quality

The `description` field is critical — it's how Copilot decides whether to auto-invoke the skill.

**Bad**: "A skill for testing" (too vague, will trigger on any test mention)
**Good**: "Write unit tests for TypeScript functions using Vitest. Trigger when creating new test files, adding test coverage, or when someone says 'write tests for' a specific function."

Include:
- What the skill does (action)
- When to use it (triggers)
- What it doesn't do (boundaries, if ambiguous)

## Step 5: Check for Problems

### Trigger overlap
Can a single user prompt activate multiple skills? Check:

```bash
# Look for common trigger words across skill descriptions
for f in .github/skills/*/SKILL.md; do
  echo "=== $(basename $(dirname $f)) ==="
  grep 'description:' "$f" | head -1
done
```

If "test" appears in 3 skill descriptions, they'll compete. Fix by making triggers more specific.

### Coverage gaps
Map daily/weekly workflows to skills. Any workflows without a skill?

### Trigger quality
- **Too narrow**: "deploy to staging on Tuesdays" → "deploy to any environment"
- **Too broad**: "any code task" → split into specific actions

## Step 6: Set Up Companion Resources

Skills can include companion files:

```
.github/skills/api-generator/
  SKILL.md              # Skill instructions
  templates/
    route.ts.template   # Route boilerplate
    test.ts.template    # Test boilerplate
  examples/
    user-endpoint.md    # Example of a well-built endpoint
```

Reference companion files with relative paths in SKILL.md. They load only when the skill is active (Layer 3 of progressive loading).

## Anti-Patterns

- **Trigger collision**: Multiple skills match "test." Fix with more specific descriptions.
- **Scope creep**: A skill keeps growing beyond its original purpose. Split it.
- **Staleness**: Workflow changed but skill didn't. Review skills when workflows evolve.
- **Too many skills**: >15 skills cause discovery fatigue. Consolidate overlapping skills.
- **Too few skills**: 0-2 skills means repeating the same explanations every session.
- **No auto-invocation**: Setting `disable-model-invocation: true` on everything defeats the purpose. Let the model discover skills by keeping descriptions accurate.
- **Giant descriptions**: Over 1024 characters. Keep descriptions concise — detail goes in the body.
