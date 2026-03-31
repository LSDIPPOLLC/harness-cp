---
applyTo: ".github/skills/**"
---

# Skill File Conventions

When editing skill files (SKILL.md):

- YAML frontmatter must include: `name`, `description`, `user-invocable`
- `name` must match the parent directory name, lowercase with hyphens, max 64 chars
- `description` must explain what the skill does AND when to trigger it (max 1024 chars)
- Include `argument-hint` for skills that accept input
- Body structure: Why → Steps → Anti-Patterns
- Reference companion files with relative paths
- Keep descriptions specific enough for auto-invocation to work accurately
- Prefix framework skills with `harnesscp-` to avoid namespace collisions
