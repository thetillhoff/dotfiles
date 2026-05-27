---
name: commit
description: Committing changes — message format, splitting into multiple commits, amending, CHANGELOG, roadmap cleanup, tagging, and pipeline verification. Use whenever staging or committing any changes.
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

## Pre-Commit Checks

- `.pre-commit-config.yaml` or `.git/hooks/pre-commit` exists → always run `pre-commit run --files <changed files>` and fix failures.
- Other linting tools (eslint, prettier, biome, markdownlint, task runners) → ask whether to run them.

## Roadmap Cleanup

If `ROADMAP.md` exists, remove completed items from it as part of the same commit. On version tags, do a broader sweep of everything shipped in the release.

## Amend vs New Commit

Prefer `--amend` when the change is a direct follow-up to the last commit, that commit isn't pushed yet, and a new commit would just be noise. Don't amend pushed commits or logically separate changes.

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

## Examples

```
PM-8957: docs: add DTLS-SRTP requirement to OCall ADR
PM-1234: fix: null pointer in session cleanup
chore: bump LiveKit SIP to v1.8.2
feat: add IPv6 support to SIP signaling
```
