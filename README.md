# HarnessCP

Configuration-as-code framework for VS Code Copilot with Anthropic Claude. Brings the discipline of [harness engineering](https://github.com/lyle/harness) to the Copilot ecosystem.

## What is harness engineering?

Harness engineering is the practice of deliberately configuring AI coding assistants around 7 pillars — turning a stateless tool into a context-aware, safety-bounded, continuously improving collaborator.

Without a harness, every session starts blind. The model doesn't know your build commands, coding conventions, architecture patterns, or team decisions. A good harness eliminates the first 5 minutes of every session and prevents the last 5 minutes of cleanup.

## The 7 Pillars

| # | Pillar | What it answers | Copilot mechanism |
|---|--------|-----------------|-------------------|
| 1 | **Context Engineering** | What does the model need to know? | `copilot-instructions.md` + conditional `*.instructions.md` |
| 2 | **Skill Composition** | What should the model be able to do? | `.github/skills/<name>/SKILL.md` |
| 3 | **Orchestration & Routing** | How should work be distributed? | `.github/agents/<name>.agent.md` with handoffs + subagents |
| 4 | **Persistence & State** | What should the model remember? | `.github/memory/` + SessionStart/Stop hooks |
| 5 | **Quality Gates** | How do we catch mistakes early? | `.github/hooks/*.json` across 8 lifecycle events |
| 6 | **Permissions & Safety** | What can the model do without asking? | Agent tool restrictions + PreToolUse hooks |
| 7 | **Ergonomics & Trust** | How should the model communicate? | Instructions + per-agent personality |

## Copilot vs Claude Code: Where the ecosystems differ

| Capability | Claude Code | VS Code Copilot | Verdict |
|------------|-------------|-----------------|---------|
| Context scoping | Monolithic `CLAUDE.md` | Conditional instructions with glob patterns | Copilot stronger |
| Skill system | Manual-only commands | Auto-invocation, progressive loading, open standard | Copilot stronger |
| Agent routing | Advisory (in skill text) | First-class agents with tool restrictions, handoffs, model selection | Copilot stronger |
| Memory | Built-in memory system | None — must be engineered | Claude Code stronger |
| Hooks | 3 events, env vars | 8 events, JSON I/O, structured permissions | Copilot stronger |
| Permissions | Central `settings.json` | Distributed across agents + hooks | Different |
| Ergonomics | CLAUDE.md instructions | Instructions + per-agent personality | Roughly equal |

## Skills

HarnessCP provides 13 skills for bootstrapping, auditing, and improving Copilot harnesses:

### Master & Cross-Cutting
- `/harnesscp-engineer` — Master router that dispatches to the right skill
- `/harnesscp-init` — Bootstrap a complete harness from scratch
- `/harnesscp-audit` — Evaluate an existing harness against all 7 pillars (scored 0-21)
- `/harnesscp-loop` — Continuous improvement: audit, identify weakest pillar, improve, validate, repeat

### Atomic (one per pillar)
- `/harnesscp-scaffold` — Generate `copilot-instructions.md` and `.github/` directory structure
- `/harnesscp-context` — Optimize context across instruction files
- `/harnesscp-memory` — Design and maintain the file-based memory system
- `/harnesscp-permissions` — Configure agent tool restrictions and permission hooks
- `/harnesscp-hooks` — Design hooks across all 8 lifecycle events
- `/harnesscp-skills` — Decompose workflows into a composed skill system
- `/harnesscp-routing` — Design agent orchestration with handoffs and subagents
- `/harnesscp-gates` — Create quality gates and validation feedback loops
- `/harnesscp-ergonomics` — Tune interaction style and per-agent personality

## Maturity Scoring

Each pillar is scored 0-3 (absent, basic, solid, excellent) for a total out of 21:

| Range | Level |
|-------|-------|
| 0-5 | Nascent |
| 6-10 | Developing |
| 11-15 | Solid |
| 16-18 | Advanced |
| 19-21 | Elite |

Run `/harnesscp-audit` to score your harness.

## Quick Start

1. Open your project in VS Code with GitHub Copilot and Claude selected as the model
2. Copy the `.github/skills/` directory from this repo into your project
3. In Copilot Chat, type `/harnesscp-init` to bootstrap your harness
4. Type `/harnesscp-audit` to see your maturity score
5. Type `/harnesscp-loop` to iteratively improve

## The Memory Gap

VS Code Copilot has no built-in memory system. HarnessCP solves this with:

- **Storage**: `.github/memory/` directory with typed files and `MEMORY.md` index
- **Injection**: SessionStart hook that auto-injects relevant memories into every session
- **Capture**: Stop hook that prompts the model to save new learnings before ending
- **Curation**: Dedicated `memory-curator` agent restricted to memory file operations

This is convention-enforced, not platform-enforced. It works when the model follows instructions consistently — which Claude does well. Memory is the discipline test for Copilot harness engineering.

## Boundaries

Where Copilot harness engineering excels:
- Granular context via conditional instructions with glob patterns
- First-class agent orchestration with tool restrictions and handoffs
- Rich hook lifecycle (8 events with JSON I/O)
- Cross-model routing per agent

Where it hits walls:
- Memory requires engineering (not built-in)
- Permissions are distributed (harder to audit)
- No built-in eval framework
- Hook format differs from Claude Code (no matcher syntax)
- Agent Plugin system is still preview

## License

MIT
