---
name: claude-md-writer
description: Write and update project CLAUDE.md files with extreme brevity. Use when user says "add to CLAUDE.md", "update CLAUDE.md", "reduce CLAUDE.md bloat", or "CLAUDE.md too long". Enforces telegraphic style (token savings > readability) while preserving critical details and nuances.
---

# CLAUDE.md Writer

Write/update project CLAUDE.md files with extreme token efficiency.

## Core Principle

**Token savings > human readability, BUT preserve critical details/nuances.**

Project CLAUDE.md is read during EVERY task. Every unnecessary word multiplies across all future sessions.

## When to Use

- User says "add to CLAUDE.md" or "document in CLAUDE.md"
- User says "CLAUDE.md too long" or "reduce token bloat"
- After significant feature/architecture changes needing documentation

## Content Rules

**Include:**

- ✅ Rules only - Crisp, actionable, 1-2 sentences per item
- ✅ Code references - `file:line` format when context needed
- ✅ Rationale in code comments - Not in docs (code comments cheaper than doc bloat)

**Exclude:**

- ❌ Case studies, examples, success stories
- ❌ "How this was discovered" narratives
- ❌ Detailed walkthroughs or step-by-step tutorials
- ❌ Historical context ("initially", "we discovered", "after testing")

## Telegraphic Style Guide

**Allowed compressions:**

- Drop articles (a, the) where context clear
- Drop subjects where obvious
- Semicolons instead of separate sentences
- Parentheses for details instead of new sentences
- List format with bullets/semicolons instead of prose
- Tech abbreviations OK (dirs, args, configs, vars, env)
- Incomplete sentences accepted when unambiguous

**Examples:**

✅ **GOOD - Telegraphic but complete:**

```markdown
**CRITICAL: Always use `pyright`** (no args). Respects pyrightconfig.json
which excludes `.venv`. Never pass directory arguments (bypasses config).
```

❌ **BAD - Over-compressed, lost critical detail:**

```markdown
Use pyright. Respects config.
```

✅ **GOOD - Preserved "only on X changes" nuance:**

```markdown
Both projects use Lambda Layers for dependencies (cached separately).
Layer rebuilds only on `pyproject.toml` changes, not code changes.
```

❌ **BAD - Lost WHEN rebuild happens:**

```markdown
Lambda uses layers. Dependencies cached.
```

## Red Flags (Do NOT Cut)

**NEVER sacrifice:**

- Critical edge cases: "only if X, not Y"
- Error conditions: "fails if...", "raises if..."
- Sequencing constraints: "before/after X", "only on Y changes"
- Subtle distinctions: runtime vs deploy-time, env var vs Secrets Manager
- Non-obvious rationale: "prevents X", "avoids Y"

## Adding New Content

**Before writing, ask:**

1. Does Claude really need this? (Challenge necessity)
2. Can this be a code comment instead?
3. Can this reference existing code (`file:line`) instead of explaining?
4. Is this a rule or just an example? (Keep rules only)

**Format:**

```markdown
### Section Title

Rule in 1-2 sentences. Technical details (compressed). Commands: `example`, `commands`.
```

## Reducing Existing Content

**Process:**

1. Read section granularly (20-30 line chunks)
2. Identify reduction targets:
   - Code examples (keep only if essential)
   - Walkthroughs/narratives (compress to rules)
   - Historical context (remove)
   - Duplicate info (consolidate)
3. Propose diff with before/after line counts
4. Wait for approval (y/n pattern)
5. Apply edit
6. Track savings (running total)

**Reduction Patterns:**

**Pattern 1: Examples → Rules**

```markdown
// Before (15 lines with examples)
**Examples:**
- User: "Can you show trip cancellation reasons?" → Create Task
- You hit tool limitation → Create Bug
- User reports incorrect data → Create Bug

// After (2 lines)
User requests feature → Task. Bug/limitation → Bug ticket.
```

**Pattern 2: Process → Commands**

```markdown
// Before (12 lines with bash blocks)
**Test Execution:**
```bash
just test               # Quick run
just test-all           # All tests
just test-coverage      # Full report
```

// After (1 line)
Commands: `just test`, `just test-coverage`, `just check`.

```

**Pattern 3: History → Current State**
```markdown
// Before (40 lines of status/milestones)
**Status:**
- ✅ 2-Lambda async architecture complete
- ✅ Transport-agnostic design implemented
- ✅ Self-improvement loop tested
[extensive history]

// After (2 lines)
Status: Deployed to test env. Multi-turn working.
```

## Complete Examples

### Adding New Content

✅ **GOOD:**

```markdown
### Jira Task Management Skill

Use `jira-task-manager` Skill for Jira ops. Loads automatically when user asks about Jira.
```

❌ **BAD - Too verbose:**

```markdown
### Jira Task Management Skill

We have created a skill called `jira-task-manager` that you should use whenever
you need to interact with Jira. This skill will be automatically loaded when the
user asks about Jira tasks. It provides comprehensive functionality for viewing,
creating, and updating tickets in the DAVE project.
```

### Reducing Content

✅ **GOOD - Preserved key info:**

```markdown
// Before (42 lines with examples)
### Type Safety & Robustness
[extensive explanation with code examples and validation patterns]

// After (4 lines, kept essentials)
### Type Safety & Robustness
All models use Pydantic v2.5+ (runtime validation, frozen=True) + pyright
strict mode. Pre-commit hooks enforce type checks + tests. Core models:
Message, ConversationContext, AgentResponse, ProcessorEvent.
```

## Workflow Summary

**For adding content:**

1. Challenge necessity (does Claude need this?)
2. Write telegraphic-style rule (1-2 sentences)
3. Link to code (`file:line`) instead of explaining
4. No examples unless essential

**For reducing content:**

1. Read section in chunks
2. Remove examples/walkthroughs/history
3. Compress to telegraphic rules
4. Preserve critical nuances (edge cases, constraints)
5. Track token savings
