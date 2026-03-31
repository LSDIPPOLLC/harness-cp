---
name: harnesscp-scaffold
description: >
  Generate a tailored copilot-instructions.md and .github/ directory structure for
  any project using VS Code Copilot. Use this skill whenever someone needs to create
  instructions from scratch, set up their .github/ directory, generate initial project
  configuration for Copilot, or bootstrap a new repo. Trigger on: "create instructions",
  "set up copilot for this project", "scaffold my config", "generate instructions",
  "write copilot-instructions.md", or any request to create foundational harness files.
  Also trigger when someone says "copilot doesn't understand my project" — that means
  the scaffold is missing or inadequate.
argument-hint: "project path or description"
user-invocable: true
---

# HarnessCP Scaffold

Generate a project-tailored `copilot-instructions.md`, conditional instruction files, and `.github/` directory structure by analyzing the codebase. The scaffold is the foundation — every other harness pillar builds on top of it.

## Why scaffolding matters

Without instructions, the model starts every conversation blind. It doesn't know your build commands, coding style, architecture patterns, or team conventions. A good scaffold eliminates the first 5 minutes of every session where you'd otherwise be re-explaining context.

VS Code Copilot has a richer context system than monolithic instruction files — it supports **conditional instructions** that load only when relevant files are active. The scaffold skill leverages this for progressive disclosure from day one.

## Step 1: Detect the Tech Stack

Read these files to understand the project. Check each one — don't assume they exist:

**Package/build manifests:**
- `package.json` — Node.js/JS/TS projects (scripts, dependencies, engines)
- `pyproject.toml` / `setup.py` / `requirements.txt` — Python projects
- `Cargo.toml` — Rust projects
- `go.mod` — Go projects
- `Gemfile` — Ruby projects
- `pom.xml` / `build.gradle` — Java/Kotlin projects
- `Makefile` / `justfile` / `Taskfile.yml` — Task runners
- `docker-compose.yml` / `Dockerfile` — Container setup

**Code style configuration:**
- `.editorconfig` — Universal editor settings
- `.prettierrc` / `.prettierrc.json` — Prettier config
- `.eslintrc*` / `eslint.config.*` — ESLint config
- `tsconfig.json` — TypeScript configuration
- `.rubocop.yml` — Ruby style
- `ruff.toml` / `pyproject.toml [tool.ruff]` — Python linting
- `.clang-format` — C/C++ formatting

**CI/CD:**
- `.github/workflows/` — GitHub Actions
- `.gitlab-ci.yml` — GitLab CI
- `Jenkinsfile` — Jenkins
- `vercel.json` / `netlify.toml` — Deployment platforms

**Testing:**
- `jest.config.*` / `vitest.config.*` — JS test frameworks
- `pytest.ini` / `conftest.py` — Python testing
- `cypress/` / `playwright.config.*` — E2E testing

## Step 2: Analyze Git History

```bash
# Commit message style (conventional? freeform? ticket prefixed?)
git log --oneline -20

# Most active directories (where does work happen?)
git log --pretty=format: --name-only -50 | sort | uniq -c | sort -rn | head -20

# Contributors (team size context)
git shortlog -sn --no-merges | head -10
```

This tells you: what the commit conventions are, which parts of the codebase are active, and whether this is a solo or team project.

## Step 3: Extract Domain Engineering Patterns

Read actual source files to extract the team's established patterns. These opinions prevent the model from writing structurally correct but stylistically alien code.

**Sample 5-10 representative files** from the most active directories (identified in Step 2). For each relevant domain, look for:

### Frontend (React/Vue/Svelte/etc.)
- **Component patterns**: Functional vs. class? Props inline or extracted? Default or named exports?
- **State management**: Redux, Zustand, Context, signals, stores? Where does state live?
- **Data fetching**: React Query, SWR, custom hooks, fetch wrappers?
- **Styling**: CSS modules, Tailwind, styled-components? Naming conventions?

### Backend / API
- **API client patterns**: HTTP client structure? Error handling? Response typing?
- **Validation**: Where and how? Middleware, decorators, schemas?
- **Error handling**: Custom error classes? How errors propagate?
- **Database access**: ORM or raw? Repository pattern? Migration strategy?

### General
- **File organization**: Feature-based or layer-based? Co-location rules?
- **Testing philosophy**: Unit-heavy or integration-heavy? Mocking policy?
- **Naming conventions**: camelCase, snake_case, PascalCase? Consistency rules?

```bash
# Find the most-changed source files (these reflect the team's patterns)
git log --pretty=format: --name-only -100 | grep -E '\.(ts|tsx|js|jsx|py|go|rs|rb)$' | sort | uniq -c | sort -rn | head -10
```

Read those files and document the patterns you observe — not the patterns you'd recommend.

## Step 4: Scan Architecture

```bash
# Directory structure (top 2 levels)
find . -maxdepth 2 -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/venv/*' | sort

# Entry points
ls -la src/index.* src/main.* src/app.* app.* index.* main.* 2>/dev/null
```

## Step 5: Generate copilot-instructions.md

Structure with the most important sections first (the model pays more attention to content near the top):

```markdown
# Project Name

Brief description of what this project does.

## Build & Run

```bash
# Install dependencies
<detected install command>

# Run development server
<detected dev command>

# Run tests
<detected test command>

# Run single test
<detected single-test command>

# Lint / format
<detected lint command>
```

## Code Style

- Language: <detected>
- Formatting: <tool and key settings>
- Naming: <conventions observed>
- Error handling: <patterns used>

## Architecture

- `src/` — <purpose>
- `src/components/` — <purpose>
- `tests/` — <purpose>
- Key patterns: <observed patterns>

## Engineering Standards

### Component Patterns
- <How to write components — composition, props, state>

### State Management
- <Where state lives and how it's managed>

### Testing Philosophy
- <What to test and how — behavioral over structural>
- <Mocking policy: what gets mocked, what doesn't>

## Commit Conventions

<detected from git log>

## Memory

This project uses a file-based memory system at `.github/memory/`.
The index is `MEMORY.md`. When you learn something that should persist
across sessions, write a memory file and update the index.
```

### Adaptation rules

- Only include sections you have evidence for. Don't guess.
- Monorepos: add a section describing each package/app.
- Keep total length under 200 lines for small projects, under 400 for large ones.
- **Engineering Standards are the highest-value section** after Build & Run. Be opinionated — document what the team actually does, not alternatives.
- Don't duplicate what's in config files. Say "follow .eslintrc" instead of listing rules.

## Step 6: Generate Conditional Instruction Files

This is where HarnessCP goes beyond what a monolithic instruction file can do. Create `.instructions.md` files for each distinct domain in the project.

### When to create conditional instructions

Create a conditional file when:
- The project has distinct file types with different conventions (e.g., `.tsx` components vs `.test.ts` test files)
- Different parts of the codebase follow different patterns (e.g., API routes vs frontend components)
- Verbose guidance is needed for specific domains but would bloat the main instructions

### Format

```markdown
---
applyTo: "**/*.tsx"
---

# React Component Conventions

- Functional components only, use arrow functions
- Props interface extracted above the component
- Named exports, no default exports
- Co-locate styles in `<Component>.module.css`
```

### Common conditional files

| File | `applyTo` | Content |
|------|-----------|---------|
| `react.instructions.md` | `**/*.tsx` | Component patterns, hook conventions, JSX style |
| `test.instructions.md` | `**/*.test.*` | Testing philosophy, mocking policy, assertion style |
| `api.instructions.md` | `**/api/**` | Route patterns, validation, error handling |
| `python.instructions.md` | `**/*.py` | Python-specific conventions, type hints, docstrings |
| `styles.instructions.md` | `**/*.css` | CSS/SCSS conventions, naming, responsive patterns |

Store these in `.github/instructions/`.

Only create conditional files where you found distinct patterns in Step 3. Don't create speculative files.

## Step 7: Create Directory Structure

```
.github/
├── copilot-instructions.md     # Always-on project instructions
├── instructions/               # Conditional instruction files
│   ├── <domain>.instructions.md
│   └── ...
├── skills/                     # Custom skills (populated by other harness skills)
├── agents/                     # Custom agents (populated by harnesscp-routing)
├── hooks/                      # Hook definitions (populated by harnesscp-hooks)
└── memory/                     # Memory system (populated by harnesscp-memory)
    └── MEMORY.md               # Memory index (start empty)
```

Create the directories and seed `MEMORY.md`:

```markdown
# Memory Index

<!-- Memories will be added as the project evolves -->
```

## Step 8: Present and Confirm

Show the generated files to the user. Ask:
1. "Does this accurately describe your project?"
2. "Anything missing or wrong in the instructions?"
3. "Any team conventions I should add?"
4. "Which conditional instruction files would be most valuable?"

Iterate based on feedback before writing final versions.

## Anti-Patterns

- **Too generic**: "This is a TypeScript project" is useless. Be specific: "SvelteKit app using TypeScript strict mode, Tailwind CSS, deployed to Vercel."
- **Too verbose**: Don't paste config files. Summarize key settings.
- **Missing build commands**: The #1 thing the model needs. Without this, every session starts with "how do I run the tests?"
- **Over-creating conditional files**: Only create them for patterns you observed. Three well-targeted files beat ten speculative ones.
- **Duplicating config**: If `.prettierrc` exists, say "format with Prettier" — don't list the Prettier config in instructions.
- **Stale information**: Instructions written once and never updated teach the model wrong things.
