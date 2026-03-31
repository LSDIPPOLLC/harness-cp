---
name: harnesscp-engineer
description: >
  The master skill for VS Code Copilot harness engineering. Use this skill
  whenever someone wants to set up, improve, audit, or maintain their Copilot
  harness — including copilot-instructions.md, conditional instructions, hooks,
  memory, permissions, skills, agents, or any aspect of how the model interacts
  with their project. Trigger on: "set up my harness", "improve my copilot config",
  "audit my setup", "add hooks", "fix my permissions", "optimize context",
  "bootstrap this project for copilot", or any request about configuring how
  Copilot works with a codebase. Also trigger when someone is struggling with
  the model's behavior — that's usually a harness problem.
argument-hint: "what harness problem to solve"
user-invocable: true
---

# HarnessCP Engineer

Master router for harness engineering. Understands what the user needs and dispatches to the right specialist skill — or handles it directly if simple.

## The 7 Pillars

Every harness engineering task maps to one or more pillars:

1. **Skill Composition** → `/harnesscp-skills`
2. **Context Engineering** → `/harnesscp-context`
3. **Orchestration & Routing** → `/harnesscp-routing`
4. **Persistence & State** → `/harnesscp-memory`
5. **Quality Gates & Feedback Loops** → `/harnesscp-gates`
6. **Permission & Safety Boundaries** → `/harnesscp-permissions`, `/harnesscp-hooks`
7. **Ergonomics & Trust Calibration** → `/harnesscp-ergonomics`

Plus cross-cutting workflows:
- **Bootstrap** → `/harnesscp-scaffold` (generates initial instructions and config)
- **Continuous Improvement** → `/harnesscp-audit` (evaluates), `/harnesscp-loop` (iterates)

## Routing Logic

### Step 1: Classify the request

| Intent | Route to | Examples |
|--------|----------|---------|
| New project setup | `/harnesscp-init` | "set up copilot", "bootstrap harness", "initialize" |
| Evaluate existing setup | `/harnesscp-audit` | "audit my harness", "what's missing", "score my setup" |
| Continuous improvement | `/harnesscp-loop` | "improve my harness", "iterate", "make it better" |
| Instructions creation | `/harnesscp-scaffold` | "create instructions", "scaffold my config" |
| Context optimization | `/harnesscp-context` | "instructions too long", "optimize context" |
| Memory system | `/harnesscp-memory` | "set up memory", "audit memories", "copilot keeps forgetting" |
| Permissions | `/harnesscp-permissions` | "fix permissions", "restrict agent tools", "too many prompts" |
| Hooks | `/harnesscp-hooks` | "add a hook", "auto-format", "auto-lint", "hook not working" |
| Skill design | `/harnesscp-skills` | "what skills do I need", "skill decomposition" |
| Agent orchestration | `/harnesscp-routing` | "design agents", "handoff workflow", "when to use subagents" |
| Quality gates | `/harnesscp-gates` | "add quality checks", "catch drift", "auto-test" |
| Interaction tuning | `/harnesscp-ergonomics` | "too verbose", "stop asking", "trust calibration" |
| Unclear / broad | Start with `/harnesscp-audit` | "help with my harness", "make copilot work better" |

### Step 2: Assess scope

- **Single pillar**: Invoke the atomic skill directly.
- **Multiple pillars**: Execute skills in sequence, validating between each.
- **Full bootstrap**: Use `/harnesscp-init` which composes multiple skills.
- **Vague request**: Start with `/harnesscp-audit` to assess, then recommend.

### Step 3: Execute

When invoking a skill:
1. Follow its step-by-step workflow in the context of the user's request
2. After completion, check if the work revealed needs in adjacent pillars
3. Offer to continue with related improvements

When handling multiple skills in sequence:
1. Present the plan: "I'll address X first, then Y"
2. Execute each skill's workflow
3. Validate that changes don't conflict
4. Summarize what was done across all pillars

## Direct Handling

For simple requests that don't need a full skill workflow:

- "What hooks do I have?" → Read `.github/hooks/*.json` and report
- "Show me my agents" → Read `.github/agents/*.agent.md` and list
- "How big are my instructions?" → Read and count lines
- "What's in my memory?" → Read `MEMORY.md` and summarize
- "What skills do I have?" → List `.github/skills/*/SKILL.md`

Threshold: if the answer requires analysis, design, or multiple file changes, invoke a skill. If it's a quick lookup, handle it directly.

## Cross-Cutting Concerns

After any skill execution, check for ripple effects:
- Added a new agent? → Check permissions (does it have appropriate tool restrictions?)
- Changed instructions? → Check context budget (still under 300 lines?)
- Added hooks? → Check gates coverage (are the right lifecycle events covered?)
- Created skills? → Check for trigger overlap (do descriptions collide?)
- Updated memory? → Check index sync (does MEMORY.md match actual files?)
