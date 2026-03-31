---
name: harnesscp-loop
description: >
  Continuous improvement loop for VS Code Copilot harnesses. Use this skill when
  someone wants to iteratively improve their harness, run an improvement cycle,
  grind through enhancements, or set up ongoing maintenance. Trigger on: "improve
  my harness", "iterate", "make it better", "improvement cycle", "grind", "keep
  improving", or any request for iterative harness enhancement. Also trigger after
  an audit reveals gaps.
argument-hint: "specific pillar to improve or 'auto' for weakest"
user-invocable: true
---

# HarnessCP Loop

Continuous improvement cycle for Copilot harnesses. Follows the pattern: audit, identify weakest pillar, improve it, validate, log, repeat.

## Why loops matter

A one-time setup gets you to "basic." Continuous improvement gets you to "excellent." Each loop iteration raises one pillar by one point, turning a nascent harness into an elite one over a few sessions.

## The Improvement Cycle

```
Audit (or use recent audit)
    ↓
Identify weakest pillar
    ↓
Route to atomic skill
    ↓
Execute improvement
    ↓
Validate (re-score the pillar)
    ↓
Log the improvement
    ↓
Continue or stop
```

## Step 1: Audit (or Reuse)

If an audit was done recently in this session, reuse those scores. Otherwise, run `/harnesscp-audit` to get fresh scores.

If resuming from a previous session, check for an improvement log memory:

```bash
cat .github/memory/project_harness_improvements.md 2>/dev/null
```

## Step 2: Select the Target Pillar

### Default: lowest score first

Raise the floor before polishing the ceiling. If multiple pillars tie, use the dependency order:

```
scaffold → context → permissions → hooks → memory → skills → routing → gates → ergonomics
```

Earlier pillars create foundations that later pillars build on.

### User override

If the user specifies a pillar, respect their priority. They know their pain points.

### Skip criteria

If all pillars are at 3 (score 21/21), congratulate the user and suggest maintenance mode: periodic re-audits to catch drift.

## Step 3: Route to Atomic Skill

| Pillar | Score < 1 (create) | Score 1-2 (improve) |
|--------|-------------------|---------------------|
| Context | `/harnesscp-scaffold` | `/harnesscp-context` |
| Skills | `/harnesscp-skills` | `/harnesscp-skills` |
| Routing | `/harnesscp-routing` | `/harnesscp-routing` |
| Memory | `/harnesscp-memory` | `/harnesscp-memory` |
| Gates | `/harnesscp-hooks` | `/harnesscp-gates` |
| Permissions | `/harnesscp-permissions` | `/harnesscp-permissions` |
| Ergonomics | `/harnesscp-ergonomics` | `/harnesscp-ergonomics` |

When creating from scratch (score 0), use the foundational skill. When improving (score 1-2), use the optimization skill.

## Step 4: Execute the Improvement

Follow the routed skill's workflow in the context of raising the pillar score by one point.

Focus on what moves the score:
- **0 → 1**: Create the basic artifacts (instructions, hooks, memory directory)
- **1 → 2**: Add coverage, fix gaps, improve quality (conditional instructions, multi-event hooks, typed memories)
- **2 → 3**: Polish, optimize, add advanced features (progressive disclosure, subagent gates, feedback capture)

## Step 5: Validate

After the improvement, re-score the targeted pillar:

1. Re-read the artifacts that changed
2. Apply the scoring rubric from `/harnesscp-audit`
3. Confirm the score increased

If the score didn't increase, diagnose why:
- Was the improvement insufficient? → Continue with the skill
- Was the rubric misunderstood? → Re-read scoring criteria
- Was the improvement in the wrong area? → Reassess

## Step 6: Log the Improvement

Create or update a project memory tracking improvements:

```markdown
---
name: harness-improvements
description: Log of harness improvement iterations with before/after scores
type: project
---

| Date | Pillar | Before | After | What Changed |
|------|--------|--------|-------|-------------|
| 2026-03-31 | Context | 0 | 1 | Created copilot-instructions.md with build commands and architecture |
| 2026-03-31 | Memory | 0 | 2 | Set up memory directory, SessionStart/Stop hooks, curator agent |
```

This enables session continuity — a future loop can pick up where the last one left off.

## Step 7: Continue or Stop

Present the updated score and ask:

```
Pillar improved: Context 0 → 1
Current score: 8/21 (Developing)

Next weakest: Memory (0/3)
Continue improving? (y/n)
```

### When to stop
- User says stop
- All pillars at 2+ (solid baseline achieved)
- Diminishing returns (2 → 3 improvements are polish, not foundation)
- Session time constraints

### When to continue
- Score under 11 (not yet "Solid")
- User wants to keep going
- Next improvement is quick (5-10 minutes)

## Parallel Improvements (Advanced)

Some pillars are independent and can be improved simultaneously:

**Safe to parallelize:**
- Memory + Permissions (different files)
- Skills + Hooks (different directories)
- Context + Ergonomics (different aspects of instructions)

**Must serialize:**
- Scaffold before Context (scaffold creates the file that context optimizes)
- Hooks before Gates (gates build on hook infrastructure)
- Routing depends on Skills (agents route to skills)

## Anti-Patterns

- **Improving without auditing first**: You need baseline scores to measure progress. Always start with an audit.
- **Skipping validation**: Improving a pillar without re-scoring means you don't know if it worked.
- **Polishing before foundations**: Raising a 2 to 3 while other pillars are at 0. Raise the floor first.
- **No improvement log**: Without logging, each session starts over. The log enables continuity.
- **Improving everything at once**: Focus on one pillar per iteration. Thoroughness beats breadth.
