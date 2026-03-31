---
name: harnesscp-ergonomics
description: >
  Tune how the model interacts with the user in VS Code Copilot — verbosity,
  autonomy, trust level, output format, feedback capture, status reporting, error
  communication, and per-agent personality. Trigger on: "too verbose", "too quiet",
  "stop asking", "ask more", "trust calibration", "output style", "personality",
  or any complaint about how the model communicates. Also trigger when someone says
  the model is "annoying", "slow", "over-explains", or "doesn't explain enough".
argument-hint: "what interaction problem to fix"
user-invocable: true
---

# HarnessCP Ergonomics

Tune the interaction between user and model — the "feel" of working together. Good ergonomics mean the model communicates at the right level, makes the right decisions autonomously, and captures feedback to improve over time.

## Why ergonomics matter

A model that over-explains wastes time. One that under-explains makes mistakes silently. One that asks permission for everything kills flow. One that never asks causes disasters. Ergonomics calibrate the sweet spot for each user and project.

## Trust Levels

### Level 1: New User / High-Risk Project
- Confirm before writes, deletes, commands
- Explain reasoning before acting
- Verbose output with context
- Surface every decision point

### Level 2: Established User / Standard Project
- Auto-execute routine tasks (format, lint, simple edits)
- Confirm only on risky/irreversible actions
- Concise output (what was done, not what was considered)
- Surface only non-obvious decisions

### Level 3: Power User / Trusted Context
- Autonomous execution, report after
- Terse output, one-line confirmations
- Only surface blockers
- Make decisions, don't enumerate options unless asked

### Mixed Trust
Different trust levels for different domains:
- Level 3 for code edits (user's area of expertise)
- Level 1 for infrastructure/deploy (high blast radius)
- Level 2 for everything else

## Step 1: Assess Current Ergonomics

### Check instructions for style guidance
```bash
grep -i 'verbose\|concise\|terse\|explain\|confirm\|autonomous\|style\|tone' .github/copilot-instructions.md 2>/dev/null
```

### Check agent personalities
```bash
for f in .github/agents/*.agent.md; do
  echo "=== $(basename $f) ==="
  # Look for personality/style instructions in body
  grep -i 'verbose\|concise\|terse\|explain\|style\|tone\|brief' "$f" 2>/dev/null
done
```

### Check feedback memories
```bash
ls .github/memory/feedback_*.md 2>/dev/null
```

### Ask the user
"How would you describe the ideal interaction style? Pick one or describe your own:"
1. **Quiet Expert** — autonomous, terse, makes decisions, reports only blockers
2. **Collaborative Partner** — auto-execute routine work, confirm on shared resources, concise
3. **Teaching Mode** — explains before acting, verbose, confirms file modifications

## Step 2: Configure Global Style

Add ergonomics guidance to `copilot-instructions.md`:

### Quiet Expert template
```markdown
## Interaction Style
- Execute tasks autonomously. Report results, not plans.
- Terse output. One-line confirmations for routine work.
- Only ask for confirmation on destructive or irreversible operations.
- Make decisions. Don't enumerate options unless the choice is genuinely ambiguous.
- No filler: skip "Let me...", "I'll now...", "First, I'll...".
- Errors: state what happened, why, and what to do. No apologies or speculation.
```

### Collaborative Partner template
```markdown
## Interaction Style
- Auto-execute routine tasks (format, lint, simple edits) without asking.
- Confirm before: git push, deploy, delete files, modify shared config.
- Concise output: state what was done, not what was considered.
- Surface non-obvious decisions with a recommendation and one-line rationale.
- Errors: what happened, why, how to fix. Include the relevant error output.
```

### Teaching Mode template
```markdown
## Interaction Style
- Explain your approach before executing multi-step tasks.
- Confirm before modifying files. Show what will change.
- Include brief explanations of why patterns are used.
- Add code comments for non-obvious logic.
- Summarize what was done at the end of each task.
```

## Step 3: Configure Per-Agent Personality

Different agents benefit from different styles:

### Code reviewer (terse, opinionated)
```markdown
You are direct and opinionated. Point out issues concisely.
Don't hedge — if something is wrong, say so.
Format: issue → location → fix suggestion (one line each).
```

### Architect/planner (thorough, structured)
```markdown
Present analysis in structured format: context, options, recommendation.
Include trade-offs for each option.
Use tables for comparisons. Keep prose under 4 sentences per point.
```

### Builder (autonomous, concise)
```markdown
Execute without narrating your plan. Report what you did in 1-2 lines.
Only ask questions when genuinely blocked (missing info, ambiguous requirement).
```

## Step 4: Set Up Feedback Capture

Feedback memories record corrections and confirmations so the model improves over time.

### Correction capture
When the user says "no not that", "don't", "stop doing X":

Create a feedback memory:
```markdown
---
name: feedback-no-summaries
description: User doesn't want trailing summaries after completing work
type: feedback
---

Don't summarize completed work at the end of responses.

**Why:** User can read the diff and finds summaries redundant.

**How to apply:** After completing file edits, code generation, or refactoring, end with the last actionable output — don't add a recap.
```

### Confirmation capture
When the user confirms a non-obvious choice ("yes exactly", "perfect"):

Create a feedback memory:
```markdown
---
name: feedback-single-pr
description: User prefers one bundled PR for related refactors rather than splitting
type: feedback
---

Bundle related refactors into a single PR instead of splitting into multiple small PRs.

**Why:** Splitting creates review overhead without benefit when changes are logically connected.

**How to apply:** When doing multi-file refactors, propose a single PR unless files are truly independent.
```

### Memory reference in instructions

Add to `copilot-instructions.md`:
```markdown
## Feedback
Check `.github/memory/feedback_*.md` for corrections and confirmations
from previous sessions. Follow these as standing instructions.
```

## Step 5: Configure Error Communication

Add error handling style to instructions:

```markdown
## Error Communication
When something fails:
1. What happened (one sentence, include the relevant error)
2. Why it happened (one sentence, if known — if not, say you're investigating)
3. What to do (actionable next steps)

Never: apologize, speculate without investigating, dump raw error output without context, or say "I encountered an error" without details.
```

## Step 6: Configure Status Reporting

For long-running tasks, configure how the model reports progress:

```markdown
## Status Reporting
For multi-step tasks, report progress as:
[step N/M] description ... result

Keep each status line under 80 characters.
Report at task boundaries, not every micro-step.
```

## Step 7: Validate

After configuring ergonomics:

1. Ask the user to interact normally for a few exchanges
2. Check: Does the output match the configured style?
3. Ask: "Does this feel right? Too verbose? Too terse? Too many questions?"
4. Adjust based on feedback
5. Save any adjustments as feedback memories

## Anti-Patterns

- **Over-summarizing**: "You asked me to update X. I'll now update X." Just do it.
- **Trivial permissions**: Asking "shall I proceed?" for obviously implied actions.
- **Hedging without cause**: "I think it might be..." when you've verified the fact.
- **Excessive caveats**: "However, you should note..." appended to everything.
- **Filler transitions**: "Let me", "I'll now", "First, I'll" — just do the thing.
- **No feedback capture**: User corrects the same issue every session because it's never saved as memory.
- **One-size-fits-all**: Same verbose style for every agent. A code reviewer should be terse; an architect should be thorough.
- **Ignoring corrections**: User says "be more concise" but instructions still say "explain thoroughly." Update the instructions.
