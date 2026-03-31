---
name: harnesscp-routing
description: >
  Design agent orchestration for VS Code Copilot — custom agents with tool
  restrictions, handoff workflows, subagent delegation, model selection, and
  build-loop patterns. Use this skill when designing how agents collaborate,
  when to delegate vs. keep inline, how to parallelize independent work, or
  how to build multi-phase task workflows. Trigger on: "design agents",
  "agent orchestration", "handoff workflow", "subagent", "parallelize",
  "build loop", "when to use agents", or any question about multi-agent coordination.
argument-hint: "what orchestration problem to solve"
user-invocable: true
---

# HarnessCP Routing

Design how agents collaborate in VS Code Copilot — when to delegate, how to parallelize, what tools each agent gets, and how handoffs work between specialists.

## Why routing matters

A single general-purpose agent can do everything, but not well. Specialist agents with restricted tools are safer (a review agent can't accidentally edit files), more focused (context isn't diluted with irrelevant capabilities), and more trustworthy (tool restrictions enforce the principle of least privilege).

VS Code Copilot's agent system is a significant upgrade over advisory routing:
- **Tool restrictions**: Each agent only has access to the tools it needs
- **Handoffs**: Agents can transition to other agents with pre-filled prompts
- **Subagents**: Agents can spawn child agents for delegated work
- **Model selection**: Different agents can use different models (Claude Opus for complex reasoning, Sonnet for fast dispatch)

## Agent vs. Inline Decision

### Use an agent when:
- Task is self-contained (clear inputs/outputs)
- Task needs a different tool set (read-only reviewer vs. full editor)
- Task benefits from a different model (fast model for search, powerful model for design)
- Task is risky (isolate with restricted tools)
- Task needs a different persona (terse reviewer vs. verbose explainer)

### Keep inline when:
- Task is trivial (overhead exceeds benefit)
- Tight iteration with user is needed (agents can't easily ask follow-ups)
- Steps are tightly coupled (shared state between steps)

## Step 1: Map Agent Roles

Survey the project's needs and define specialist roles:

### Common agent archetypes

| Role | Tools | Model | Purpose |
|------|-------|-------|---------|
| **Explorer** | readFile, listFiles, search | Sonnet (fast) | Codebase search, pattern finding |
| **Planner** | readFile, listFiles, search | Opus (powerful) | Architecture design, task breakdown |
| **Builder** | readFile, editFiles, listFiles, search, runCommand | Opus | Feature implementation, bug fixes |
| **Reviewer** | readFile, listFiles, search | Sonnet | Code review, pattern checking |
| **Tester** | readFile, editFiles, runCommand | Sonnet | Test writing, test running |
| **Deployer** | readFile, runCommand | Opus | Build, deploy, verify |
| **Memory Curator** | readFile, editFiles, listFiles | Sonnet | Memory file management |

Not every project needs all roles. Start with what the workflow demands.

## Step 2: Design Agent Files

### File format

```yaml
---
name: agent-name
description: "What this agent does — shown as chat placeholder text"
tools:
  - readFile
  - editFiles
  - listFiles
  - search/codebase
  - runCommand
agents:
  - "explorer"
  - "tester"
model: ["claude-opus-4-6", "claude-sonnet-4-6"]
---

Agent instructions here. Define persona, constraints, and workflow.
```

### Key frontmatter fields

| Field | Purpose | Example |
|-------|---------|---------|
| `tools` | Restrict available tools | `[readFile, listFiles, search/codebase]` for read-only |
| `agents` | Which subagents can be spawned | `["explorer", "tester"]` or `"*"` for all |
| `model` | Model preference (tries in order) | `["claude-opus-4-6", "claude-sonnet-4-6"]` |
| `handoffs` | Transition buttons to other agents | See handoff section below |
| `hooks` | Agent-scoped hooks | Hooks that only run for this agent |

### Tool restriction patterns

**Read-only** (safest):
```yaml
tools: [readFile, listFiles, search/codebase, search/workspace]
```

**Build/test** (can execute but not push):
```yaml
tools: [readFile, editFiles, listFiles, search/codebase, runCommand]
```

**Full access** (development):
```yaml
tools: [readFile, editFiles, listFiles, search/codebase, search/workspace, runCommand, web/fetch]
```

**MCP tools** (external services):
```yaml
tools: [readFile, "mcp-server-name/*"]
```

## Step 3: Design Handoff Workflows

Handoffs create guided multi-step workflows where one agent transitions to another:

```yaml
handoffs:
  - label: "Review changes"
    agent: "code-reviewer"
    prompt: "Review the changes I just made"
    send: false
  - label: "Write tests"
    agent: "test-writer"
    prompt: "Write tests for the code I just implemented"
    send: true
  - label: "Deploy"
    agent: "deployer"
    prompt: "Deploy the current branch to staging"
    send: false
```

### Handoff design principles

- **Label**: Short action text shown as a button (e.g., "Review changes")
- **send: false**: Show the prompt for user to review/edit before sending
- **send: true**: Auto-send immediately (for routine follow-ups)
- **Model override**: Handoffs can switch models (fast model for review, powerful for implementation)

### Common handoff chains

```
Feature development:
  Planner → Builder → Tester → Reviewer

Bug fix:
  Explorer → Builder → Tester

Code review:
  Reviewer → Builder (if fixes needed) → Reviewer (re-review)

Deploy:
  Tester → Deployer → Explorer (verify)
```

## Step 4: Design Subagent Strategy

### When to use subagents vs. handoffs

| Mechanism | Use when | User involvement |
|-----------|----------|-----------------|
| **Handoff** | User should see and control the transition | High — user clicks button, can edit prompt |
| **Subagent** | Delegation should happen automatically | Low — parent agent decides |
| **Inline** | Work is trivial or tightly coupled | None — same agent handles it |

### Subagent nesting control

```yaml
# Parent can spawn explorer and tester
agents: ["explorer", "tester"]

# Parent can spawn any agent
agents: "*"

# Parent cannot spawn subagents
agents: []
```

Restrict subagent access to prevent runaway delegation. A reviewer agent shouldn't spawn a builder agent — that bypasses the review purpose.

## Step 5: Design Build-Loop Patterns

For complex multi-phase tasks, use the build-loop pattern:

```
1. Assess current state (what's done, what's next)
2. Pick next phase from plan
3. Route to specialist agent (via handoff or subagent)
4. Collect output
5. Validate (tests pass, requirements met)
6. Log progress
7. Repeat until done
```

### Implement as an agent with handoffs

```yaml
---
name: build-loop
description: "Multi-phase task orchestrator. Assesses state, routes to specialists, validates, repeats."
tools: [readFile, listFiles, search/codebase, runCommand]
agents: ["explorer", "builder", "tester"]
handoffs:
  - label: "Implement next phase"
    agent: "builder"
    send: false
  - label: "Run tests"
    agent: "tester"
    send: true
  - label: "Explore codebase"
    agent: "explorer"
    send: false
---
```

### Phase design principles
- Each phase produces a testable artifact
- Ordered by dependency (foundation before features)
- Small enough to validate (3-5 files per phase)
- Designed for rollback (revert to previous phase if validation fails)

## Step 6: Parallelization Strategy

### What to parallelize
- Independent research (find usages + read config + check tests)
- Independent validation (lint + test + type-check)
- Multi-file analysis (review 5 files for the same pattern)
- Exploration + planning (one agent explores, another plans)

### What to serialize
- State-changing sequences (branch → edit → commit → push)
- Dependent analysis (find entry point → trace calls → identify bug)
- User-facing decisions (present options → get input → execute)
- Same-file modifications (merge conflicts)

### Model selection for parallelism

Use faster models for parallel exploratory work, powerful models for synthesis:

```yaml
# Explorer: fast model for parallel search
model: ["claude-sonnet-4-6"]

# Planner: powerful model for synthesis
model: ["claude-opus-4-6"]
```

## Step 7: Error Handling

### Agent failure modes

| Failure | Response |
|---------|----------|
| Wrong output | Validation catches it, re-route with constraints |
| Timeout | Decompose into smaller tasks |
| Goes off-track | Improve task brief in handoff prompt |
| Corrupts state | Use restricted tools to prevent; git revert if needed |

### Retry strategy
1. Same agent, more specific instructions
2. Different agent or approach
3. Escalate to user (3 retries = signal for human judgment)

## Anti-Patterns

- **God agent**: One agent with all tools and no restrictions. Split into specialists.
- **Over-delegation**: Using subagents for trivial tasks. Inline is faster for simple work.
- **Missing tool restrictions**: Agents default to all tools. Always specify `tools` explicitly.
- **Circular handoffs**: Agent A hands off to B, which hands off back to A. Design one-way chains.
- **No validation between phases**: Build loop that never checks if the previous phase succeeded.
- **Wrong model for the job**: Using Opus for fast search (expensive, slow) or Sonnet for complex design (insufficient).
- **Subagent sprawl**: Agents spawning agents spawning agents. Limit nesting depth with the `agents` field.
