---
name: git
description: >
  All git and GitHub operations: committing, PR creation/editing, reviewing PR comments/CI, pushing, tagging, branch history cleanup, CHANGELOG updates. Use whenever the user stages changes, asks to commit, create/update a PR, check PR feedback, fix failing CI, push a tag, squash/regroup local commits, or run any git or gh command. Also triggers on: "check the PR", "what did reviewers say", "why is CI failing", "squash these commits", "clean up history", "tag and push".
permissions:
  allow:
    - "Bash(git status)"
    - "Bash(git status *)"
    - "Bash(git diff *)"
    - "Bash(git log *)"
    - "Bash(git branch *)"
    - "Bash(git show *)"
    - "Bash(git blame *)"
    - "Bash(git tag --sort*)"
    - "Bash(find * -name .git *)"
    - "Bash(gh pr list *)"
    - "Bash(gh pr checks *)"
    - "Bash(gh pr view *)"
    - "Bash(gh pr checks)"
    - "Bash(gh run list *)"
    - "Bash(gh run view *)"
    - "Bash(gh repo view *)"
    - "Bash(gh repo list *)"
    - "Bash(gh api *)"
    - "Bash(gh issue list *)"
    - "Bash(gh issue view *)"
    - "Bash(gh release list *)"
    - "Bash(gh release view *)"
---

# Git & GitHub

## Command Style

Always `cd <path> && git <subcommand>`. Repos live at `~/code/<owner>/<repo>/`. If `.git` root unclear: `find ~/code/<owner>/<repo> -name .git -maxdepth 3 -type d`.

Use SSH URLs for all `git clone`: `git@github.com:<owner>/<repo>.git` — never HTTPS.

**Stage and commit in separate tool calls — never chain them.** Run `git add <files>` first, then `git commit` separately. This lets the user review exactly what's staged. Never write `git add ... && git commit ...`.

**Batch read-only commands into one call:**

```bash
cd <path> && echo '=== STATUS ===' && git status && echo '=== DIFF ===' && git diff --cached && echo '=== LOG ===' && git log --oneline -10
```

One approval for all context gathering.

`git push -f` is aliased to `--force-with-lease`. `git pull` is aliased to `--rebase`.

---

## Commits

### Format

```text
[TICKET: ]<type>: <short description>
```

One line, imperative mood, lowercase after type, no period, ~60 chars max (excluding ticket prefix). Describe *what* and *why*, not *how* or *where* — no file names unless they're the subject.

**Types:** `feat` · `fix` · `chore` · `refactor` · `docs` · `test` · `style`

**Ticket prefix:** Extract from branch name (pattern: letters + hyphen + digits, e.g. `PM-1234`), uppercase it.

- `PM-8957-livekit-adr` → `PM-8957:`
- `feature/no-ticket` → no prefix

**Examples:**

```text
PM-8957: docs: add DTLS-SRTP requirement to OCall ADR
fix: null pointer in session cleanup
chore: bump LiveKit SIP to v1.8.2
feat: add IPv6 support to SIP signaling
```

### Pre-Commit Checks

1. Run the `review-comments` skill on the staged diff. Fix violations before committing.
2. Run `codespell` on changed files (default) or all tracked files (when the user asks to
   verify/check/review/sweep the whole repo):

   ```bash
   # Default — changed files only (pre-commit)
   git diff --name-only HEAD | xargs codespell

   # Full sweep — all tracked files
   git ls-files | xargs codespell
   ```

   Review every flagged word — most will need fixing, but some are false positives (proper nouns,
   abbreviations, intentional non-standard words). Fix real typos, ignore the rest. Do **not** add
   false positives to a word list; just leave them. If `codespell` is not installed, warn:

   > `codespell` not found — install it with `brew install codespell`, then re-run.

3. `.pre-commit-config.yaml` or `.git/hooks/pre-commit` exists → run `pre-commit run --files <changed files>`, fix failures.
4. Other linters (eslint, prettier, markdownlint) → ask whether to run them.

### Sensitive Content Check

Check if repo is public:

```bash
gh repo view --json isPrivate --jq '.isPrivate'
```

If public (or check fails), scan staged diff for: private keys, API tokens (`sk-`, `AKIA...`, `ghp_`, `Bearer ey`), hardcoded `password =`/`secret =`/`api_key =` with real values, `.env` files staged, internal hostnames/VPN endpoints. When in doubt, warn and ask before proceeding.

### Test Verification

Scan staged diff for changed source files. Skip for: docs, config, CI/CD, build scripts, migrations, UI markup.

- Changed file has logic but no test counterpart → ask: *"No tests for `<file>` — add them or proceed?"*
- Changed file already has tests → run them, confirm pass.

---

## Local History Review

Before committing, run:

```bash
git log origin/<branch>..HEAD --oneline
```

Use `main` if no tracking branch.

**Splitting staged changes:** If staged diff touches multiple independent concerns, split into separate commits — one per concern. Ask before splitting an *existing* commit.

**Amend** — direct follow-up to the last unpushed commit (missed file, typo).

**Squash into earlier local commit** — staged change fixes a bug introduced by a local commit, or logically completes one. Use `git reset --soft` to the commit before the target, re-stage selectively, recommit.

**New commit** — logically independent of all local commits.

### Full History Regroup

When many small commits need collapsing:

#### Step 1 — Scope

```bash
git log origin/<branch>..HEAD --reverse --format="%H %s"
```

#### Step 2 — Understand

```bash
git log origin/<branch>..HEAD --reverse -p   # per-commit diffs
git diff origin/<branch>..HEAD --stat         # overall shape
```

#### Step 3 — Design target commit set

Group by *what they fix or add*. One concern, one commit. Tests belong with the code they test. Config/docs that exist solely to support a feature belong with that feature. Aim for 3–7 commits for a typical feature branch. Go straight to Step 4 — don't present a plan first.

#### Step 4 — Rewrite

```bash
git reset --soft origin/<branch>
# All local changes now staged.
```

For each group: unstage all (`git reset HEAD -- .`), stage only the group's files, commit. Verify: `git status` clean, `git diff origin/<branch>..HEAD --stat` matches original.

#### Step 5 — Run tests

Don't rebase interactively across merge commits — use `reset --soft`. Don't create a staging branch. Don't ask for confirmation before starting; show result after.

---

## Pushed Commits Are Immutable

Never amend, reword, squash, reorder, or force-push a commit already pushed to remote — unless the user explicitly asks. Confirm with `git log origin/<branch>..HEAD` that a commit is local-only before touching it.

---

## CHANGELOG & Versioning

If `CHANGELOG.md` exists:

1. Check current version: `git tag --sort=-v:refname | head -5`
2. Propose bump: `major` (breaking), `minor` (features), `patch` (fixes/chore/refactor)
3. Add `## vX.Y.Z` at top, or rename `## Unreleased`. Keep dependency entries generic.
4. Stage `CHANGELOG.md` with the commit.

After committing, ask: *"Tag as `vX.Y.Z` and push?"* If confirmed:

```bash
git tag vX.Y.Z && git push origin <branch> && git push origin vX.Y.Z
```

### Pipeline Verification After Tag

If `.github/workflows/` has tag-triggered workflows:

1. `gh run list --limit 5` — check for runs triggered by the tag.
2. On failure: `gh run view <id> --log-failed` — report the failing step.

---

## Roadmap Cleanup

If `ROADMAP.md` exists, remove completed items as part of the same commit. On version tags, sweep everything shipped in the release.

---

## Pull Requests

### MANDATORY before `gh pr create` or `gh pr edit`

Always invoke this section before writing any PR title or body.

**Anti-patterns to avoid:**

- Emojis anywhere
- Claude Code footer in body (already in commits)
- Marketing language ("game-changing", "revolutionary")
- Filler ("This PR aims to...", "The purpose of this change is...")
- Redundant info already in commits

### PR Title

Format: `<type>: <description>` — max 72 chars, imperative mood, no period, no emojis.

Choose type by **user impact**, not internal complexity:

- `feat` — new user-facing capability
- `fix` — bug fix
- `refactor` — internal restructure, users don't notice
- `chore` — maintenance, deps, tooling
- `docs` / `test` / `perf`

`refactor` only if users cannot observe the change. Removing/adding capabilities → `feat` or `chore`.

### PR Description Template

```markdown
## Summary
[Purpose: what this PR accomplishes and why. 1 paragraph or 3-5 bullets.
Focus on the outcome, not the implementation. Rough strokes only — the diff shows the details.]

## Context
[Optional: 1-2 sentences of background if the motivation is non-obvious]

## Related
- Closes #123
```

### Branch Workflow

Never push feature commits directly to `main`. Always:

1. Create a feature branch off the current state: `git checkout -b <branch-name>`
2. Push the branch: `git push -u origin <branch-name>`
3. Create the PR from that branch
4. Reset local `main` back to the pre-feature SHA: `git checkout main && git reset --hard <base-sha>`

This keeps local `main` clean and in sync with remote `main`.

### Branch Cleanup After Merge

After merging a branch (locally or via PR), always delete it in both places:

```bash
git branch -d <branch-name>
git push origin --delete <branch-name>
```

`-d` (safe delete) refuses if the branch is unmerged. Use `-D` only when the user explicitly asks to force-delete an unmerged branch. If the remote branch doesn't exist (e.g. was already deleted by GitHub's auto-delete), `push --delete` will error harmlessly — that's fine.

### Description Scope

Describe the rough strokes - what changed and why. Do **not** list specific files, function names, or code-level details; GitHub's diff shows those. The description should give a reviewer the context they need to understand the purpose and approach, not a narration of the code.

### Writing Workflow

1. `gh pr view <number> --json title,body` — read current state if updating
2. `git log --oneline origin/main..HEAD` — see every commit that will merge
3. Group commits by purpose; identify main fix vs supporting changes
4. Draft description from template; major changes first; rough strokes only (see Description Scope above)
5. Write title reflecting PRIMARY purpose
6. Remove all slop (emojis, hyperbole, filler)
7. Verify title-body consistency: title should reflect the Summary. If body says "Removes Athena + Adds KPI tool" but title only says "Add KPI tool", fix both together: `gh pr edit <number> --title "..." --body "..."`

### PR Description Checklist

- [ ] Title: `<type>: <description>` format, ≤72 chars
- [ ] Title matches Summary
- [ ] No emojis, no Claude Code footer, no marketing language
- [ ] Description covers the purpose and what the changes accomplish - not a commit list or code-level narration
- [ ] Related PRs/issues linked if applicable

---

## Checking PR Feedback & CI

1. Get branch: `git branch --show-current`
2. Find PR: `gh pr list --head <branch> --json number,url`
3. Fetch inline review comments:

   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | "---\n**\(.user.login)** on `\(.path)` (line \(.original_line // .line // "N/A")):\n\(.body)\n"'
   ```

4. Fetch general comments:

   ```bash
   gh api repos/{owner}/{repo}/issues/{number}/comments --jq '.[] | "---\n**\(.user.login)** (general comment):\n\(.body)\n"'
   ```

5. Check CI: `gh pr checks`
6. For failing checks: `gh run view <run-id> --log-failed`

Get `owner/repo`: `gh repo view --json nameWithOwner --jq '.nameWithOwner'`

Present: review comments first, then general comments, then CI status. Summarize actionable items. For CI failures, suggest the fix. Ask if user wants to address any.
