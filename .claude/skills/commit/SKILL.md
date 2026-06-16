---
name: commit
description: Committing changes — reviewing local history for squash/amend opportunities, message format, splitting into multiple commits, CHANGELOG, roadmap cleanup, tagging, and pipeline verification. Use whenever staging or committing any changes, and when the user asks to squash, clean up, regroup, or consolidate local commits.
---

# Commit Messages

## Format

```
[TICKET: ]<type>: <short description>
```

- One line, imperative mood, lowercase after type, no period, ~60 chars max (excluding ticket prefix)
- Describe *what* changed and *why*, not *how* or *where* — no file names or paths unless they're the subject of the change

## Types

- `feat` — new feature or capability
- `fix` — bug fix
- `chore` — maintenance, dependencies, CI
- `refactor` — restructuring without behavior change
- `docs` — documentation only
- `test` — adding or fixing tests
- `style` — formatting, whitespace, linting

## Ticket Prefix

Extract the ticket ID from the branch name (pattern: letters + hyphen + digits, e.g. `PM-1234`), uppercase it.

- `PM-8957-livekit-adr` → `PM-8957: `
- `feature/no-ticket` → no prefix

## Test Verification

Scan staged diff for changed source files. Skip for: docs, config, CI/CD, build scripts, migrations, UI markup.

- Changed file has significant logic but no test counterpart → ask: *"No tests found for `<file>` — add them or proceed?"*
- Changed file already has tests → run them and confirm they pass.

## Sensitive Content Check

Before committing, check whether the repo is public:

```bash
gh repo view --json isPrivate --jq '.isPrivate'
```

If the repo is public (or the check fails and you can't confirm it's private), scan the staged diff for sensitive content. Stop and warn the user — do not commit — if any of the following are found:

- **Private keys** — `-----BEGIN ... PRIVATE KEY-----`, `-----BEGIN EC PRIVATE KEY-----`, etc.
- **API tokens / credentials** — patterns like `sk-`, `AKIA[A-Z0-9]{16}`, `ghp_`, `gho_`, `xoxb-`, `xoxp-`, `Bearer ey`, `Authorization:` with a value
- **Hardcoded secrets in config** — assignments like `password =`, `secret =`, `api_key =`, `token =` with a non-placeholder value (i.e. not `""`, `<...>`, `$ENV_VAR`, or `os.getenv`)
- **`.env` files being staged** — any `.env`, `.env.local`, `.env.production`, etc.
- **Internal or company-specific material** — internal hostnames, VPN endpoints, internal service URLs, or anything that looks like it identifies internal infrastructure

When in doubt, flag it and ask the user to confirm before proceeding. A false positive is far less costly than an accidental secret leak.

## Pre-Commit Checks

- Run the `review-comments` skill on the staged diff. Fix any violations before committing — good comments are a commit requirement, not optional. This is always on; don't skip it.
- `.pre-commit-config.yaml` or `.git/hooks/pre-commit` exists → always run `pre-commit run --files <changed files>` and fix failures.
- Other linting tools (eslint, prettier, biome, markdownlint, task runners) → ask whether to run them.

## Roadmap Cleanup

If `ROADMAP.md` exists, remove completed items from it as part of the same commit. On version tags, do a broader sweep of everything shipped in the release.

## Pushed Commits Are Immutable

Never amend, reword, squash, reorder, or otherwise rewrite a commit that has already been pushed to the remote — unless the user explicitly asks for it. This includes `--amend`, `reset --soft`, interactive rebase, and force-push. When in doubt, check `git log origin/<branch>..HEAD` to confirm a commit is local-only before touching it.

## Local History Review

Before creating a new commit, check whether the staged change belongs with an existing unpushed commit:

```bash
git log origin/<branch>..HEAD --oneline
```

Use `main` (or the relevant base branch) if there is no tracking branch yet.

**Amend** — staged change is a direct follow-up to the last commit (missed file, typo, forgotten rename) and that commit is not pushed.

**Squash into an earlier local commit** — staged change fixes a bug introduced by a local commit, or logically completes one. The combined commit would be cleaner than two separate ones. Use `git reset --soft` to the commit before the target, re-stage selectively, and recommit.

**New commit** — the change is logically independent of all local commits.

### Full history regroup

When there are many small local commits to collapse into logical units:

**Step 1 — Establish scope**

```bash
git log origin/<branch>..HEAD --reverse --format="%H %s"
```

These are the only commits in scope.

**Step 2 — Understand what changed**

Read three layers of signal:

1. Per-commit diffs — the most precise grouping signal. Two commits that touch the same function or subsystem are strong candidates to merge.
   ```bash
   git log origin/<branch>..HEAD --reverse -p
   ```
2. Inline comments added in the diff — explain *why* a change exists, which often determines which concern it belongs to.
3. Commit messages — useful for intent, but treat as hints. "fix" tells you little; "fix: normalize AOR before store key" tells you exactly.

Also get the overall shape: `git diff origin/<branch>..HEAD --stat`

**Step 3 — Design the target commit set**

Group by *what they fix or add*, not by file or order written:

- One concern, one commit. If you can't write the message without "and", split it.
- Tests belong with the code they test.
- Config, docs, and infra that exist solely to support a feature belong with that feature commit.

Aim for 3–7 commits for a typical feature branch. Go straight to Step 4 — don't present a plan or ask for approval first.

**Step 4 — Rewrite the history**

```bash
git reset --soft origin/<branch>
# All local changes are now staged.
```

For each logical group:
1. Unstage everything: `git reset HEAD -- .`
2. Stage only the files for this group: `git add <files>`
3. Commit with a focused message

Repeat until all staged changes are committed. Verify nothing was lost: `git status` should be clean and `git diff origin/<branch>..HEAD --stat` should match the original from Step 2.

**Step 5 — Run tests**

Run the project's test suite to confirm the final state is correct.

**What not to do**

- Don't rebase interactively across merge commits — use `reset --soft` instead.
- Don't create a staging branch or worktree — work in place.
- Don't ask for confirmation before starting the regroup; just do it and show the result.

## CHANGELOG & Versioning

If `CHANGELOG.md` exists:

1. Check current version: `git tag --sort=-v:refname | head -5`
2. Propose a bump: `major` (breaking), `minor` (new features), `patch` (fixes, chore, refactor)
3. Add `## vX.Y.Z` at the top, or rename `## Unreleased` if it exists. Keep dependency entries generic ("Update dependencies").
4. Stage `CHANGELOG.md` with the commit.

After committing, ask: *"Tag this as `vX.Y.Z` and push the tag?"* If confirmed: `git tag vX.Y.Z && git push origin <branch> && git push origin vX.Y.Z`.

## Pipeline Verification

After pushing a version tag, if `.github/workflows/` has tag-triggered workflows:

1. Run `gh run list --limit 5` and check for runs triggered by the tag.
2. On failure: `gh run view <id> --log-failed` and report the failing step.

## Git Command Style

Always `cd <path> && git <subcommand>`. Repos live at `~/code/<owner>/<repo>/`. If the `.git` root is unclear: `find ~/code/<owner>/<repo> -name .git -maxdepth 3 -type d`.

**Batch info-gathering into one call.** Combine all read-only git commands (status, diff, log, tag, branch) into a single shell invocation separated by `&&` and `echo` delimiters so the user only approves once:

```bash
cd <path> && echo '=== STATUS ===' && git status && echo '=== DIFF ===' && git diff --cached && echo '=== LOG ===' && git log --oneline -10 && echo '=== BRANCH ===' && git branch --show-current
```

Add or remove sections as needed (e.g. `git tag --sort=-v:refname | head -5` when CHANGELOG exists). The key rule: **one approval for all read-only context gathering.**

## Examples

```
PM-8957: docs: add DTLS-SRTP requirement to OCall ADR
PM-1234: fix: null pointer in session cleanup
chore: bump LiveKit SIP to v1.8.2
feat: add IPv6 support to SIP signaling
```
