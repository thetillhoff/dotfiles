---
name: contribute-to-open-source
description: >
  Use when contributing a feature or fix to an upstream open source project,
  either directly or via a fork. Covers the full lifecycle: reading the repo
  before writing code, sizing your PR for reviewability, commit message
  conventions per ecosystem, writing a PR body that gets merged, anticipating
  the most common reviewer feedback topics, and keeping internal tooling out of
  the contribution.
---

# Contributing to Open Source Projects

## Core principle

The upstream repo must be able to build your branch with no local state.
Every check in this skill guards against leaking local paths, internal
tooling, or transient testing aids into the contribution.

---

## Before You Write Code

Read before touching anything.

```bash
# What commit style does this repo use?
git log --oneline -20

# Is there a CONTRIBUTING.md, HACKING.md, or docs/contributing/?
ls CONTRIBUTING* docs/contributing* .github/CONTRIBUTING* 2>/dev/null

# What does a recently merged PR look like?
gh pr list --repo <owner/repo> --state merged --limit 5
```

Check for:

- A CLA (Contributor License Agreement) - many large projects require signing before review starts
- An issue requirement - some repos (kubernetes, rust-lang) require a linked issue or RFC before accepting PRs
- A PR template (`.github/pull_request_template.md`) - fill it completely; reviewers skip PRs that skip the template
- CI requirements - what tests must pass; run them locally before pushing

---

## PR Size: What Actually Gets Merged

Data from 19 large open source repos (curl, kubernetes, helm, prometheus,
grafana, flux2, vscode, react, vue, django, rust, docker compose, terraform,
ruff, uv, ohmyzsh, gh cli, neovim - July 2026):

**Merged PRs (median across repos):**

- ~10-50 lines added, ~5-20 lines deleted
- 1-3 files changed
- 1-2 commits

**Rejected PRs tend to be:**

- Larger (often 10-100x more additions)
- More files touched
- More commits (suggesting churn/iteration before close)

The pattern is consistent: **small, focused PRs get merged faster and with
fewer comments.** Most repos merged in under 2 days for small PRs. Larger
PRs that did merge (rust, vscode) were from established contributors.

**Rule:** If your diff touches more than 5-7 files or adds more than 200
lines, ask yourself if it can be split. A PR that does one thing is reviewed
in one sitting.

---

## Commit Messages: What Each Repo Expects

The ecosystem almost predicts the style:

| Ecosystem / Repo | Style | Examples |
| --- | --- | --- |
| Go projects (kubernetes, helm, flux2, terraform, gh cli) | Upper-case imperative | `Fix race condition in reconciler` |
| Rust projects (rust-lang, ruff, uv) | Upper-case imperative | `Add SIMD-accelerated parser` |
| JavaScript/TypeScript (vscode, react) | Upper-case imperative | `Fix agent host checkpoint timing` |
| Python (django) | Sentence-form, no trailing period | `Fixed #37191 -- Prevented ValueError in FileBasedCache` |
| Vue/Nuxt ecosystem | `fix(scope): message` conventional | `fix(runtime-vapor): preserve slot anchors` |
| Prometheus, ohmyzsh, docker/compose | Mixed conventional | `chore: update maintainers info` |
| curl | Lower-case imperative | `digest: escape double quotes in realm` |
| neovim | Lower-case imperative | `fix(cmdwin): cmdwin is scrollbinded` |

**Read the existing git log before writing your first commit.** Match the
style exactly. Conventional commits (`feat:`, `fix:`) are only correct in
repos that actually use them - forcing them into curl or kubernetes marks you
as someone who did not read the codebase.

### Commit body

Most repos only require the subject line for small fixes. Use the body when:

- The change has a non-obvious reason (workaround, spec requirement, known issue)
- The change fixes a bug: include `Fixes #<issue>` or equivalent
- The commit is large: briefly explain the approach chosen and alternatives discarded

---

## What Reviewers Actually Comment On

From comment-topic analysis across merged and rejected PRs:

**Testing** is the #1 or #2 topic in almost every repo (curl, k8s, helm,
prometheus, grafana, vue, django, rust, neovim). The pattern: reviewers ask
for tests that cover the new behavior or edge case. **Include tests in your
first PR submission.** Do not leave them for a follow-up commit.

**Correctness** is consistently in the top 3 (curl, helm, vue, django, rust,
react). Reviewers catch off-by-ones, wrong condition direction, unhandled
nil/error paths.

**Docs** is top-3 for many repos (k8s, grafana, vue, docker, ruff, astral/uv,
neovim). Public API changes need doc updates in the same PR. For repos that
use `--` reference style (Django, curl manpages), update the docs file too.

**Style** comes up most in tightly-maintained projects with automated linters
(django, curl). Run `make lint` / `golangci-lint` / `ruff check` / the repo's
specific linter before pushing.

**Design/API** comments appear when a PR adds a new public interface without
prior discussion. For significant API additions, open an issue or RFC first
and get maintainer buy-in before coding.

**Scope** comments ("this should be a separate PR", "out of scope for now")
are how maintainers protect merge velocity. If your PR mixes a feature with a
refactor, split them.

---

## Why PRs Get Closed Without Merge

From close-reason analysis:

- **Duplicate** - common in all repos. Search open AND merged PRs before starting.
  `gh pr list --repo <owner/repo> --state all --search "keyword"`
- **Out-of-scope** - maintainers have a roadmap. Vue core and ohmyzsh close
  many "good idea" PRs that don't fit. File an issue first for features.
- **Breaking change without prior RFC** - helm, terraform, flux2 close PRs that
  change public API without a design proposal.
- **Abandoned/stale** - prometheus, uv close PRs left without response to
  review comments. Respond within a few days; stale bots close them in weeks.
- **No tests** - not always stated explicitly, but "needs work" closures often
  follow review threads asking for test coverage that never arrived.

Most closures in the data were "unclassified" - maintainers closed with
minimal comment. This often means scope mismatch or the change was simply not
wanted. An issue discussion before the PR avoids this.

---

## Repo-Specific Conventions

### High-velocity internal repos (kubernetes, grafana, vscode)

Most merged PRs are from the core team. External PRs face higher scrutiny.
Kubernetes alone had 10 average comments per merged PR. Expect a longer
review cycle; link to the relevant issue/SIG; follow the PR template exactly.

### "Awesome" lists (sindresorhus/awesome, awesome-selfhosted)

Rejection rate is very high (~80%+). Requirements are strict: the project must
meet star thresholds, be active, have a license, fit an existing category.
Read the repo's own contribution guidelines before submitting.

### Small focused tools (ruff, uv, ohmyzsh, neovim, cli)

Fast turnaround (< 1 day median for merged PRs). Comment volume is low.
These repos reward minimal, well-tested diffs. Match the existing code style
precisely - maintainers know their codebase intimately.

---

## Branch Hygiene

Work on a feature branch off the upstream default branch. Never commit
directly to `main`/`master` on your fork.

```bash
git checkout -b fix/short-description
```

Keep the branch name consistent with the PR title.

---

## What to Exclude from Commits

These must never appear in commits destined for the upstream repo:

| Category | Examples |
| --- | --- |
| Internal planning tools | `docs/superpowers/`, `.superpowers/`, plan/spec docs |
| Local test aids | `vendor/` dir (unless the repo uses it), patched Dockerfiles |
| Local path references | `replace` directives in `go.mod`, absolute paths |
| Task tracking | `TODO.md`, local checklists |
| IDE/editor files | `.vscode/`, `.idea/`, `.DS_Store` |
| `.gitignore` entries | lines referencing any of the above |

```bash
git diff --cached --name-only   # review before every commit
```

---

## go.mod / go.sum Rules (Go projects)

**Never commit a `replace` directive pointing to a local path.**

```go
// FORBIDDEN in any committed go.mod
replace github.com/some/dep => /Users/you/code/some/dep
```

### Workflow when your feature depends on an unreleased dep

1. Land the dep change in the dep repo first (or on its PR).
2. Get a real module proxy pseudo-version:
   `go get github.com/dep/repo@<commit-sha>`
3. Run `go mod tidy`.
4. Commit `go.mod` + `go.sum` pointing at the pseudo-version.

For local testing only (never committed):

```bash
go mod edit -replace github.com/dep/repo=/local/path
# ... test ...
go mod edit -dropreplace github.com/dep/repo
go mod tidy
```

Verify before committing:

```bash
grep replace go.mod   # must produce no output
grep github.com/<dep> go.mod  # must show upstream owner, not your fork
```

---

## Opt-In Feature Pattern (Go)

Features that require optional native deps (CGo, external libs) should be:

1. **Disabled by default** - set `Disabled: true` or a feature flag.
2. **Non-panicking on init failure** - log and return nil; let callers handle it.
3. **Build-tag guarded** - CGo-dependent code in `_cgo.go`, stub in `_nocgo.go`.

```go
// feature_nocgo.go
//go:build !cgo
func SetFeatureEnabled(_ bool) {} // no-op stub
```

Define shared types in the non-build-tagged file so they're always available.

---

## Clean History

If earlier commits contain mistakes, fix by soft-reset, not a "revert X"
commit:

```bash
git log --oneline
git reset --soft <commit-before-bad>
git add <files>
git commit -m "..."
git push fork <branch> --force-with-lease
```

---

## Writing the PR

### Title

Match the repo's commit style (see table above). One line, imperative,
user-facing capability:

```text
fix(runtime-vapor): preserve slot anchors during unmount
```

or (for repos without conventional commits):

```text
Fix race condition in reconciler when context is cancelled
```

### Body: what must be in it

- **What** it does and why (one paragraph or bullet list)
- **How to test** - exact commands a reviewer can run, including Docker if
  needed
- **Linked issue** - `Fixes #1234` / `Closes #1234` where applicable
- Completed PR template sections (leave none blank)

### What to omit

- Internal planning doc references
- Mention of local replace directives or vendor workarounds
- File-level implementation narration (reviewers read the diff)
- AI-assistant attribution or "generated with" notes

---

## Pre-Push Checklist

```bash
# Run the repo's own lint/test/build
make test          # or: go test ./..., cargo test, pytest, npm test

# Go projects only
grep replace go.mod                        # empty → good
CGO_ENABLED=0 go build ./...              # verify non-CGo build

# All projects
git diff --cached --name-only             # no vendor/, TODO.md, .env
git log origin/main..HEAD --oneline       # each commit is self-contained
gh pr list --repo <owner/repo> --state all --search "your topic"  # no duplicate
```
