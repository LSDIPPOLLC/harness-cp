---
name: harnesscp-context
description: >
  Optimize what information the model loads and when — context budget analysis,
  instruction restructuring, progressive disclosure via conditional files, and
  context layering. Use this skill whenever copilot-instructions.md is too long,
  too short, or poorly organized, when the model seems to forget or ignore
  instructions, when context feels wasted on irrelevant info, or when designing
  what goes in always-on instructions vs. conditional files vs. memory vs. skills.
  Trigger on: "optimize context", "instructions are too long", "copilot ignores
  my instructions", "context budget", "restructure instructions", or any concern
  about information overload or gaps.
argument-hint: "what feels wrong about the current context"
user-invocable: true
---

# HarnessCP Context

Engineer what information the model loads and when. The goal is maximum relevant context with minimum waste — every token should earn its place.

## Why context engineering matters

Everything loaded — instructions, memory, skill descriptions, tool results, conversation history — competes for attention. When context is bloated with irrelevant information, the model is more likely to miss or deprioritize the instructions that matter. When it's too sparse, the model wastes time rediscovering things.

VS Code Copilot has a significant advantage here: **conditional instructions** (`*.instructions.md` with `applyTo` globs) provide native progressive disclosure. A React component instruction file only loads when working on `.tsx` files. Use this aggressively.

## Step 1: Audit Current Context Load

### Measure copilot-instructions.md

```bash
# Line count and rough token estimate (1 token ~ 4 chars)
wc -lc .github/copilot-instructions.md
```

| Size | Assessment |
|------|-----------|
| < 50 lines | Too sparse — missing critical information |
| 50-200 lines | Good for small/medium projects |
| 200-400 lines | Appropriate for large/complex projects |
| 400-600 lines | Getting heavy — move content to conditional files |
| > 600 lines | Bloated — actively hurting performance |

### Inventory all context sources

Check every source of always-loaded context:
- `.github/copilot-instructions.md` (project root)
- `AGENTS.md` or `CLAUDE.md` at project root (if enabled in settings)
- `.github/memory/MEMORY.md` index (if referenced in instructions)
- Skill descriptions from all `.github/skills/*/SKILL.md` frontmatter
- Any parent directory instructions (if `chat.useCustomizationsInParentRepositories` is enabled)

Then check conditionally-loaded context:
- `.github/instructions/*.instructions.md` (each with its `applyTo` pattern)

Estimate total always-on budget: instructions tokens + ~100 tokens per enabled skill + ~50 tokens for memory index.

### Content quality check

Read `copilot-instructions.md` and classify each section:

| Classification | Action |
|----------------|--------|
| **Critical** — build commands, code style, architecture | Keep in main instructions, front-load |
| **Domain-specific** — React patterns, test conventions, API style | Move to conditional `*.instructions.md` |
| **Useful but verbose** — detailed workflows, checklists | Move to a skill or prompt file |
| **Reference** — API docs, schemas, long lists | Move to a skill with companion files |
| **Stale** — outdated info, removed features | Delete |
| **Redundant** — duplicates config files | Delete (model can read the config) |
| **Generic** — could apply to any project | Delete or make specific |

## Step 2: Design Context Layers

### Layer 1: Always loaded (copilot-instructions.md)
Content relevant to virtually every task:
- Project identity (what is this, what does it do)
- Build/test/run commands
- Code style rules (the ones you can't infer from configs)
- Architecture overview (where things live)
- Critical constraints ("never do X because Y")
- Memory system reference

**Budget target**: 100-300 lines

### Layer 2: Conditionally loaded (*.instructions.md)
Content relevant to specific file types or directories:
- React/Vue/Svelte component conventions → `applyTo: "**/*.tsx"`
- Test writing guidelines → `applyTo: "**/*.test.*"`
- API route patterns → `applyTo: "**/api/**"`
- Database/migration conventions → `applyTo: "**/db/**"`
- CI/CD pipeline patterns → `applyTo: ".github/workflows/**"`

**This is the key differentiator from Claude Code.** Instead of cramming everything into one file and hoping the model picks out what's relevant, the platform only loads domain-specific instructions when the model is working on matching files.

**Budget**: Unlimited per file, but each should be focused on its domain.

### Layer 3: On-demand (skills and prompt files)
Content relevant to specific workflows:
- Deployment procedures → skill or prompt file
- Database migration steps → skill or prompt file
- Release process → prompt file
- Code review checklist → skill

**Budget**: Unlimited, loaded only when invoked.

### Layer 4: Discovered at runtime
Information the model can find when needed:
- File contents (model reads files as needed)
- Git history (model runs git commands)
- Config file details (model reads .eslintrc, tsconfig, etc.)
- Test patterns (model reads existing tests)

**Don't put in instructions** what the model can discover by reading a file. Say "Follow .eslintrc" instead of listing ESLint rules.

### Layer 5: Persistent memory
Information that spans conversations but isn't always relevant:
- User preferences (feedback memories)
- Project status (project memories)
- External system references (reference memories)

**Budget**: MEMORY.md index is always loaded (~50 tokens), individual memories loaded on demand.

## Step 3: Restructure

### Front-loading principle

The model pays more attention to content near the top. Order sections:
1. Build/test commands (most universally needed)
2. Code style (prevents the most common mistakes)
3. Architecture (helps navigation)
4. Constraints and warnings (prevents costly errors)
5. Memory system reference
6. Everything else

### Move domain content to conditional files

For each section in `copilot-instructions.md` that only applies to a specific file type:

1. Create `.github/instructions/<domain>.instructions.md`
2. Add YAML frontmatter with `applyTo` glob
3. Move the content
4. Replace the section in main instructions with a one-line reference if needed

Example — moving React conventions:

**Before** (in copilot-instructions.md, ~30 lines):
```markdown
## React Component Conventions
- Functional components only, use arrow functions
- Props interface extracted above the component
- Named exports, no default exports
- Use React Query for data fetching
- ... (25 more lines)
```

**After** (one line in main + conditional file):
```markdown
## React — see conditional instructions for component patterns
```

```markdown
# .github/instructions/react.instructions.md
---
applyTo: "**/*.tsx"
---
# React Component Conventions
- Functional components only, use arrow functions
- ... (full detail here, loaded only when editing .tsx files)
```

### Conciseness patterns

**Before** (verbose):
```markdown
## Testing
We use Jest for unit testing. Tests are located in the `__tests__` directory
next to the source files. When writing tests, please follow our naming convention
of using the same name as the source file with a `.test.ts` extension.
```

**After** (concise):
```markdown
## Testing
- Jest, co-located in `__tests__/` dirs
- Naming: `<source>.test.ts`
- Run: `npm test` / single: `npm test -- --testPathPattern=<file>`
```

Same information, 1/3 the tokens.

### Deduplication

Check for information that exists in config files:
- Instructions mention TypeScript AND tsconfig.json exists → remove TS details, reference tsconfig
- Instructions list ESLint rules AND .eslintrc exists → remove rules, say "follow .eslintrc"
- Instructions describe commit format AND .commitlintrc exists → reference the config

## Step 4: Optimize Conditional File Coverage

Review the `applyTo` patterns across all conditional files:

- **Gaps**: Are there file types worked on frequently that have no conditional instructions?
- **Overlaps**: Do multiple files match the same patterns? (The model receives all matching instructions — overlaps add context cost)
- **Overreach**: Does `applyTo: "**/*"` exist? That's just another always-on instruction with extra steps.

Check actual file distribution:
```bash
# What file types exist in the project?
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
```

Match conditional files to the most common and most convention-heavy file types.

## Step 5: Validate

After restructuring:

1. **Size check**: Is `copilot-instructions.md` within budget (100-300 lines)?
2. **Completeness check**: Can the model still build, test, and navigate with just the main instructions?
3. **Conditional coverage**: Do the most convention-heavy file types have conditional instructions?
4. **Accessibility check**: Is moved-out content still discoverable?
5. **Freshness check**: Is everything still accurate?

Ask the user: "I've restructured from N lines to M lines, with K conditional instruction files. Here's what changed: [summary]. Want to review?"

## Step 6: Set Up Maintenance

Context engineering isn't one-and-done. Recommend:
- Re-audit context when the main instructions exceed 400 lines
- Use the `drift-check` hook to flag stale instructions
- When adding new sections, ask "does this earn its context budget, or should it be conditional?"
- Review conditional file `applyTo` patterns quarterly — project structure evolves

Create a project memory noting when the last context optimization was done.

## Anti-Patterns

- **Monolithic instructions**: Putting everything in `copilot-instructions.md` when conditional files exist. Use the platform's progressive disclosure.
- **Empty conditionals**: Creating `applyTo` files for every possible extension without actual convention content. Only create files where you have real patterns to document.
- **Instruction inflation**: Adding new sections without removing outdated ones. Context is a budget — additions require either removals or moves to conditional files.
- **Duplicating discovery**: Writing in instructions what the model can read from config files.
- **Ignoring the memory layer**: Putting user preferences and project status in instructions instead of memory files.
