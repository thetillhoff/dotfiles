---
name: pr-writer
description: Write clear, concise PR titles and descriptions. MANDATORY before ANY `gh pr create` or `gh pr edit` command. Use when creating, updating, or reviewing PR content. Avoids AI slop - no emojis, no verbose fluff, written for humans. Focus on bullet points, technical clarity, and brevity. NEVER write PR body directly - always invoke this skill first.
---

# PR Writer

Guide for writing effective pull request titles and descriptions that are clear, concise, and free of AI-generated fluff.

## Core Principles

**Primary Goal**: Write for humans, not for AI metrics.

**Anti-Patterns to Avoid** ("AI Slop"):

- ❌ Emojis and decorative symbols
- ❌ Claude Code footer (already in git commits, no need in PR body)
- ❌ Marketing language ("game-changing", "revolutionary", "amazing")
- ❌ Excessive enthusiasm ("INCREDIBLE!", "WOW!", multiple exclamation marks)
- ❌ Verbose explanations that could be one sentence
- ❌ Redundant information already in commits
- ❌ Filler phrases ("This PR aims to...", "The purpose of this change is...")

**What to Include**:

- ✅ Bullet points for clarity
- ✅ Technical accuracy
- ✅ Context when non-obvious
- ✅ Test results only for manual/local tests (skip if CI handles it)
- ✅ Breaking changes prominently
- ✅ Related PRs/issues when applicable

## PR Title Guidelines

**Format**: `<type>: <description>`

**Types**:

- `feat`: New feature or user-facing capability
- `fix`: Bug fix
- `refactor`: Code reorganization with **no behavior change** (internal only, not user-facing)
- `chore`: Maintenance, dependencies, tooling, non-code changes
- `docs`: Documentation only
- `test`: Test changes only
- `perf`: Performance improvement

**Critical distinction - refactor vs feat/chore**:

- ✅ `refactor`: Extract service layer, rename variables, reorganize files (users don't notice)
- ❌ NOT refactor: Remove features, change behavior, add/remove capabilities (users DO notice)

**Good Titles**:

- `fix: Correct user validation in auth middleware`
- `refactor: Extract dashboard logic into service layer` (no behavior change)
- `feat: Add export functionality for analytics data`
- `chore: Remove deprecated Athena integration` (removes capability)

**Bad Titles**:

- `✨ Amazing new feature that will revolutionize everything!`
- `Fixed some stuff`
- `Update files (WIP - DO NOT MERGE!!!)`
- `refactor: Remove Athena and add dashboard routing` (behavior changed! Not refactor)

**Rules**:

- Max 72 characters
- Imperative mood ("Add", not "Added" or "Adds")
- No period at end
- No emojis
- Specific, not vague
- Choose type based on user impact, not internal complexity

## PR Description Structure

Use this template structure, adapt as needed:

```markdown
## Summary
[TLDR: 1 paragraph or 3-5 bullets covering what changed at high level]

## Context
[Optional: 1-2 sentences explaining why, if non-obvious]

## Changes

**Major Change Category**
[1 sentence: Why this change? What problem does it solve?]
- Specific change 1
- Specific change 2

**Minor changes**
- Small fix 1
- Small fix 2

## Related
- Supersedes #123
```

### Section Guidelines

**Summary** (required):

- TLDR at the top for quick scanning
- 1 paragraph OR 3-5 bullet points
- Answer: What changed + Why it matters
- High-level only - details go in Changes section

**Context** (optional):

- Use when Summary alone doesn't explain the full motivation
- 1-2 sentences max
- Background, constraints, or additional "why"
- Skip if Summary is sufficient

**Changes** (required):

- Group related changes with descriptive headers
- Each group gets 1-sentence context explaining the "why"
- Major changes first, minor changes last
- Use **Bold Headers** for change categories
- Bullet points for specific changes within each group
- Prioritize: Show major architectural/feature changes prominently, minimize space for small fixes

**Test Results** (only for manual/local tests):

- Skip if repo has CI that runs tests (results visible in GitHub Actions)
- Only include for manual test runs not covered by CI
- Format: `Tool: Result` (e.g., "Manual E2E: passed")

**Related** (use when applicable):

- Link to related PRs/issues
- Note if PR supersedes another PR
- Note if PR closes issues
- Format: `Action #number` (e.g., "Closes #123")

## Examples

### Good PR Description

```markdown
## Summary
Add email validation to authentication middleware. Fixes security issue where invalid email formats were accepted.

## Changes

**Email Validation**
Prevent invalid email formats from bypassing authentication checks.
- Add regex validation to auth middleware
- Update error messages for validation failures
- Add test cases for edge cases

## Related
- Closes #234
```

### Bad PR Description (AI Slop)

```markdown
🎉 Exciting New Authentication Improvements! 🚀

This PR introduces **AMAZING** enhancements to our authentication system that will **REVOLUTIONIZE** how we handle user validation!

The changes include:
- ✨ Brand new email validation that is **SUPER ROBUST**
- 🎨 Beautiful new error messages that users will love
- 🧪 Comprehensive test coverage that ensures **100% RELIABILITY**

This is a **GAME-CHANGING** update that transforms our entire authentication flow into something truly incredible! The team is going to absolutely love this! 💯

I'm really excited about these changes and can't wait to see them in production! 🎊
```

**What's wrong**:

- Excessive emojis (8 instances)
- Marketing hyperbole ("REVOLUTIONIZE", "GAME-CHANGING")
- Subjective enthusiasm ("AMAZING", "incredible")
- Unnecessary filler ("I'm really excited", "can't wait")
- Missing concrete technical details
- No test results
- Vague descriptions ("Beautiful new error messages")

## Writing Workflow

When asked to write or update a PR:

1. **Read current PR state**: Use `gh pr view <number> --json title,body` to see existing title and body
2. **Analyze ALL commits in PR**: Use `git log --oneline origin/main..HEAD` (or branch..HEAD) to see EVERY commit that will be merged
3. **Group commits by purpose**: Which commits are related? What's the main fix vs supporting changes?
4. **Identify complete scope**: What changed? Why? Any breaking changes? ONLY include changes from commits in step 2
5. **Check for relationships**: Does this PR supersede/close others?
6. **Draft description**: Use template, organize changes by commit groups (main changes first, supporting changes after)
7. **Write/update title**: Follow format, reflect PRIMARY purpose (the main problem solved, not every detail)
8. **Review for slop**: Remove emojis, hyperbole, filler
9. **Verify completeness**: Context clear? All commits represented? Tests shown?
10. **CRITICAL - Verify title-body consistency**: Does title accurately reflect the Summary section? If not, update BOTH title AND body together using `gh pr edit <number> --title "..." --body "..."`

**Key principle**: The PR description should cover ALL commits that will be merged (step 2), but the title should capture the PRIMARY purpose (the main problem being solved).

**Title-Body Consistency Check**:

- Title should reflect the most important change(s) in the Summary
- If body has multiple major changes, title should cover the primary one
- When updating body, always re-read title and adjust if needed
- Example: If body says "Removes Athena + Adds KPI tool" but title only says "Add KPI tool", update title to "refactor: Remove Athena and add dashboard-only routing"

## Common Scenarios

**Superseding another PR**:
Add to Related section:

```markdown
## Related
- Supersedes #123 (includes all changes plus X, Y, Z)
```

**Breaking changes**:
Call out prominently in Changes section:

```markdown
## Changes
- **BREAKING**: Rename `oldMethod()` to `newMethod()`
- Update all call sites
- Add migration guide to docs
```

**Large refactoring**:
Group changes by category:

```markdown
## Changes

**Architecture**:
- Extract service layer from controllers
- Add dependency injection

**Files moved**:
- `src/old/*` → `src/new/*`

**Tests**:
- Update import paths
- Add integration tests for new layer
```

**Documentation-only**:
Keep it minimal:

```markdown
## Changes
- Fix typos in API docs
- Update code examples for v2.0
- Add troubleshooting section
```

## Quality Checklist

Before submitting, verify:

- [ ] Title follows `<type>: <description>` format
- [ ] Title matches main changes in Summary section
- [ ] No emojis anywhere
- [ ] No Claude Code footer (already in git commits)
- [ ] No marketing language or hyperbole
- [ ] Changes section uses bullet points
- [ ] Test results omitted (CI handles it) or included (manual tests only)
- [ ] Related PRs/issues linked (if applicable)
- [ ] Length is appropriate (not too verbose)
- [ ] Everything is technically accurate
