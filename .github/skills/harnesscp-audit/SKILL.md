---
name: harnesscp-audit
description: >
  Audit and evaluate an existing VS Code Copilot harness against the 7 pillars
  of harness engineering. Use this skill whenever someone wants to assess their
  setup, find gaps, check harness quality, score their configuration maturity,
  or understand what's working and what needs improvement. Trigger on: "audit
  my harness", "what's missing", "how good is my setup", "score my config",
  "harness quality", "what should I improve", or any request to evaluate the
  current Copilot configuration.
argument-hint: "project path or specific concern"
user-invocable: true
---

# HarnessCP Audit

Evaluate an existing VS Code Copilot harness against the 7 pillars of harness engineering. Produces a maturity score (0-21) with prioritized recommendations for improvement.

## The 7 Pillars & Scoring

Each pillar is scored 0-3:

| Score | Meaning |
|-------|---------|
| 0 | **Absent** — No configuration for this pillar |
| 1 | **Basic** — Minimal setup, significant gaps |
| 2 | **Solid** — Good coverage, minor improvements possible |
| 3 | **Excellent** — Well-tuned, actively maintained |

**Maturity levels** (sum of 7 scores):
- 0-5: Nascent
- 6-10: Developing
- 11-15: Solid
- 16-18: Advanced
- 19-21: Elite

## Step 1: Gather Current State

Read all harness artifacts. Check each — don't assume they exist:

```bash
# Always-on instructions
cat .github/copilot-instructions.md 2>/dev/null
cat AGENTS.md 2>/dev/null
cat CLAUDE.md 2>/dev/null

# Conditional instructions
ls .github/instructions/*.instructions.md 2>/dev/null

# Skills
ls .github/skills/*/SKILL.md 2>/dev/null

# Agents
ls .github/agents/*.agent.md 2>/dev/null

# Hooks
ls .github/hooks/*.json 2>/dev/null
ls hooks/*.sh 2>/dev/null

# Memory
ls .github/memory/ 2>/dev/null
cat .github/memory/MEMORY.md 2>/dev/null

# VS Code settings
cat .vscode/settings.json 2>/dev/null
```

## Step 2: Score Each Pillar

### P1: Skill Composition (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No `.github/skills/` directory or skill files |
| 1 | A few skills exist but have incomplete frontmatter, vague descriptions, or no clear triggers |
| 2 | Organized skill set with proper YAML frontmatter, clear trigger descriptions, argument hints |
| 3 | Composed skill system with routing agent, companion resources, auto-invocation working, cross-skill workflows |

**Check:**
```bash
SKILL_COUNT=$(find .github/skills -name "SKILL.md" 2>/dev/null | wc -l)
# Check frontmatter quality
for f in .github/skills/*/SKILL.md; do
  grep -c 'name:\|description:\|user-invocable:' "$f" 2>/dev/null
done
```

### P2: Context Engineering (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No `copilot-instructions.md`, no `AGENTS.md`, no `CLAUDE.md` |
| 1 | Generic instructions file, no conditional `*.instructions.md` files |
| 2 | Tailored instructions + conditional instruction files scoped by `applyTo` globs |
| 3 | Optimized context budget (<300 lines main), progressive disclosure via conditionals, domain-specific files for major file types |

**Check:**
```bash
INST_LINES=$(wc -l < .github/copilot-instructions.md 2>/dev/null || echo 0)
COND_COUNT=$(find .github/instructions -name "*.instructions.md" 2>/dev/null | wc -l)
# Check for applyTo in conditional files
grep -l 'applyTo:' .github/instructions/*.instructions.md 2>/dev/null | wc -l
```

### P3: Orchestration & Routing (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No `.github/agents/` directory or agent files |
| 1 | One or two basic agents without tool restrictions or handoffs |
| 2 | Agent system with tool restrictions, defined handoff workflows between specialists |
| 3 | Full orchestration: model selection per agent, subagent chains, handoff workflows, build-loop agents |

**Check:**
```bash
AGENT_COUNT=$(find .github/agents -name "*.agent.md" 2>/dev/null | wc -l)
# Check for tool restrictions
for f in .github/agents/*.agent.md; do
  grep -c 'tools:\|handoffs:\|model:' "$f" 2>/dev/null
done
```

### P4: Persistence & State (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No `.github/memory/` directory |
| 1 | Memory directory exists but sparse/stale, no injection hooks |
| 2 | Organized memory with typed files, SessionStart injection + Stop capture hooks |
| 3 | Active curation with memory-curator agent, feedback capture, lifecycle management, index sync |

**Check:**
```bash
MEMORY_FILES=$(find .github/memory -name "*.md" ! -name "MEMORY.md" 2>/dev/null | wc -l)
INJECT_HOOK=$(grep -rl "SessionStart" .github/hooks/*.json 2>/dev/null | wc -l)
CAPTURE_HOOK=$(grep -rl '"Stop"' .github/hooks/*.json 2>/dev/null | wc -l)
CURATOR=$(ls .github/agents/memory-curator.agent.md 2>/dev/null && echo 1 || echo 0)
```

### P5: Quality Gates (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No hooks at all |
| 1 | Basic PostToolUse hooks (format or lint only) |
| 2 | Multi-event hooks: PreToolUse gates + PostToolUse validation + Stop health checks |
| 3 | Full lifecycle coverage: SubagentStart/Stop gates, PreCompact preservation, UserPromptSubmit context injection, feedback loops |

**Check:**
```bash
HOOK_EVENTS=""
for json in .github/hooks/*.json; do
  [ -f "$json" ] && HOOK_EVENTS="$HOOK_EVENTS $(jq -r '.hooks | keys[]' "$json" 2>/dev/null)"
done
echo "Events covered: $HOOK_EVENTS" | tr ' ' '\n' | sort -u
```

### P6: Permissions & Safety (0-3)

| Score | Criteria |
|-------|----------|
| 0 | Default permissions, no agent tool restrictions, no PreToolUse hooks |
| 1 | Some agents have tool restrictions OR basic PreToolUse hooks exist |
| 2 | Well-designed per-agent tool restrictions with PreToolUse safety gates |
| 3 | Layered: per-agent restrictions + dynamic PreToolUse decisions + secret scanning + dangerous command blocking |

**Check:**
```bash
# Agents with tool restrictions
for f in .github/agents/*.agent.md; do
  NAME=$(basename "$f" .agent.md)
  HAS_TOOLS=$(grep -c 'tools:' "$f" 2>/dev/null)
  echo "$NAME: tools restricted=$HAS_TOOLS"
done
# PreToolUse hooks
grep -rl "PreToolUse" .github/hooks/*.json 2>/dev/null
```

### P7: Ergonomics & Trust (0-3)

| Score | Criteria |
|-------|----------|
| 0 | No interaction style guidance anywhere |
| 1 | Basic style notes in copilot-instructions.md |
| 2 | Per-agent personality tuning + feedback memory capturing corrections/confirmations |
| 3 | Calibrated trust levels per domain, consistent cross-agent behavior, autonomy boundaries documented |

**Check**: Read instructions for tone/style guidance. Check agents for personality instructions. Check memory for feedback-type memories.

## Step 3: Present the Report

Format:

```
## Harness Maturity: X/21 (Level)

### Scores
P1 Skill Composition:     ██░░ 2/3
P2 Context Engineering:    ███░ 3/3
P3 Orchestration & Routing:█░░░ 1/3
P4 Persistence & State:   ░░░░ 0/3
P5 Quality Gates:          ██░░ 2/3
P6 Permissions & Safety:   █░░░ 1/3
P7 Ergonomics & Trust:     █░░░ 1/3

### Strengths
- [What's working well]

### Gaps
- [What's missing or weak]

### Recommendations (prioritized by impact/effort)

#### Quick Wins (high impact, low effort)
1. ...

#### High Impact (worth the investment)
2. ...

#### Long-Term (ongoing maintenance)
3. ...
```

## Step 4: Recommend Next Steps

Prioritize recommendations by:

1. **Dependencies**: Scaffold before context, context before skills
2. **Impact/effort ratio**: Quick wins first
3. **User's pain points**: Address what they're struggling with

Common priority order:
1. Context (copilot-instructions.md) — foundation for everything
2. Memory — biggest capability gap
3. Hooks — automated quality with minimal effort
4. Permissions — safety without friction
5. Skills — workflow productivity
6. Routing — agent orchestration
7. Ergonomics — polish

Offer to run `/harnesscp-loop` to start improving the weakest pillar.

## Anti-Patterns

- **Inflating scores**: Be honest. A "1" with clear improvement path is better than a generous "2" that hides gaps.
- **Auditing without reading**: Don't score based on file existence alone. Read the content to judge quality.
- **Too many recommendations**: Prioritize. Three actionable items beat ten overwhelming ones.
- **Ignoring user context**: A solo dev project doesn't need the same harness as a team project. Score relative to actual needs.
