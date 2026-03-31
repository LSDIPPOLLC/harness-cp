---
name: harnesscp-init
description: >
  Bootstrap a complete VS Code Copilot harness for a project from scratch. Use
  this skill whenever someone wants to initialize, set up, or bootstrap their
  project for Copilot — including creating copilot-instructions.md, conditional
  instructions, setting up memory, hooks, agents, and skills. Trigger on: "set
  up copilot", "initialize harness", "bootstrap this project", "create instructions",
  "configure copilot for this repo", or any request to get a project ready for
  productive Copilot usage. Also trigger when someone says "help me get started"
  or "how should I set this up".
argument-hint: "project path or description"
user-invocable: true
---

# HarnessCP Init

Composed skill that orchestrates a full project bootstrap by running multiple atomic skills in order. Takes a bare project and produces a complete, tailored Copilot harness in one pass.

## Bootstrap Sequence

Execute these phases in order. Each phase uses an atomic skill — invoke it and follow its workflow in the context of this bootstrap.

### Phase 1: Scaffold (required)

**Skill**: `/harnesscp-scaffold`

The foundation. Analyze the project and generate:
- `.github/copilot-instructions.md` with project-specific conventions
- `.github/instructions/` directory with conditional instruction files
- `.github/` directory structure (skills/, agents/, hooks/, memory/)

Present the generated instructions to the user for review before proceeding. This is the most important artifact — get it right.

### Phase 2: Permissions (required)

**Skill**: `/harnesscp-permissions`

Based on the detected tech stack from Phase 1:
- Create at least one agent with appropriate tool restrictions
- Set up basic PreToolUse hooks (command gate, secret scanner)
- Apply the principle: read-only by default, write access for builders, prompt for shared-state

### Phase 3: Memory (recommended)

**Skill**: `/harnesscp-memory`

Set up the persistence layer:
- Create `.github/memory/` directory and `MEMORY.md` index
- Create SessionStart hook for memory injection
- Create Stop hook for memory capture
- Create memory-curator agent
- Seed with project context discovered during scaffolding

Ask the user if they want memory. Simple projects may not need it.

### Phase 4: Hooks (recommended)

**Skill**: `/harnesscp-hooks`

Based on the project's tooling, recommend and create hooks:
- Auto-format on save (if Prettier, ruff, rustfmt, gofmt detected)
- Lint on edit (if ESLint, ruff detected)
- Drift check at session end

Present recommendations and let the user choose which hooks to install.

### Phase 5: Context Review (recommended)

**Skill**: `/harnesscp-context`

Final pass to validate:
- Is `copilot-instructions.md` a reasonable size (<300 lines)?
- Should any sections move to conditional instruction files?
- Are build commands front-loaded?
- Is the memory system referenced in instructions?

## Completion Checklist

After all phases, present a summary:

```
Harness Bootstrap Complete
─────────────────────────
✓ copilot-instructions.md created (N lines)
✓ Conditional instructions: N files
✓ Agents: N (with tool restrictions)
✓ Memory system initialized (N seed memories)
✓ Hooks installed: [list]
✓ Context budget: ~N tokens always-on

Recommended next steps:
- Run /harnesscp-audit after a few sessions to identify gaps
- Add feedback memories as you discover preferences
- Consider designing project-specific skills with /harnesscp-skills
- Run /harnesscp-loop to iteratively improve
```

## Adapting to Existing Harnesses

If the project already has some harness files:
- Don't overwrite existing instructions — merge or offer to rewrite
- Don't duplicate existing hooks — augment
- Don't create memory if one exists — audit it instead
- Skip phases that are already well-covered

In this case, suggest `/harnesscp-audit` instead, which evaluates and improves existing harnesses.

## What This Doesn't Do

The init skill creates the foundation. These are follow-up tasks:
- **Custom skills**: Use `/harnesscp-skills` to design project-specific workflows
- **Agent orchestration**: Use `/harnesscp-routing` to design multi-agent handoffs
- **Quality gates**: Use `/harnesscp-gates` to add advanced validation
- **Ergonomics**: Use `/harnesscp-ergonomics` to tune interaction style

Run `/harnesscp-loop` to progressively add these after the foundation is solid.
