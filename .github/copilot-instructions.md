# HarnessCP

Harness engineering framework for VS Code Copilot + Anthropic Claude. Configuration-as-code for AI coding assistants.

## Build & Run

This is a documentation and configuration project — no build step. The deliverables are Markdown skill files, JSON hook definitions, and shell scripts.

- Preview docs: open `docs/index.html` in a browser
- Validate JSON hooks: `cat .github/hooks/*.json | jq .`
- Check hook scripts: `shellcheck hooks/*.sh`
- Run evals: manual invocation of skills against test scenarios in `evals/evals.json`

## Architecture

```
.github/
  skills/          # 13 HarnessCP skills (Copilot YAML frontmatter)
  agents/          # Custom agent definitions (.agent.md)
  hooks/           # Hook definitions (JSON)
  instructions/    # Conditional instruction files
  memory/          # File-based memory system
hooks/             # Companion hook scripts (shell)
docs/              # Documentation site
evals/             # Evaluation scenarios
```

## Code Style

### Skill files (SKILL.md)
- YAML frontmatter with `name`, `description`, `argument-hint`, `user-invocable`
- `name` must match parent directory, lowercase with hyphens, max 64 chars
- `description` must explain what AND when — this is how Copilot discovers skills
- Body uses Markdown with practical step-by-step workflows
- Include anti-patterns and common pitfalls
- Reference companion files with relative paths

### Agent files (.agent.md)
- YAML frontmatter with `name`, `description`, `tools`, `agents`, `model`
- Restrict tools to minimum needed (principle of least privilege)
- Use handoffs for multi-step workflows

### Hook definitions (JSON)
- One hook per JSON file in `.github/hooks/`
- Companion scripts in `hooks/` directory
- Scripts must handle JSON stdin and produce JSON stdout
- Exit code 0 = success, 2 = block
- Always include timeout field

### Shell scripts
- Bash, POSIX-compatible where possible
- Set `set -euo pipefail` at top
- Read JSON input from stdin using jq
- Output JSON to stdout
- Include OS-specific handling when needed

## Conventions

- Prefix framework skills with `harnesscp-` to avoid namespace collisions
- Every skill follows the same structure: Why → Steps → Anti-patterns
- Skills reference the 7-pillar framework consistently
- Maturity scoring uses the standard 0-3 per pillar (0-21 total) rubric
- Memory files use typed frontmatter (user, feedback, project, reference)

## Memory

This project uses a file-based memory system at `.github/memory/`. The index is `MEMORY.md`. When you learn something that should persist across sessions, write a memory file and update the index.

## Testing

Test skills by invoking them in VS Code Copilot Chat with Claude selected:
1. `/harnesscp-audit` should produce a valid 0-21 maturity score
2. `/harnesscp-scaffold` should generate project-specific instructions
3. Hook scripts should accept JSON stdin and produce valid JSON stdout
