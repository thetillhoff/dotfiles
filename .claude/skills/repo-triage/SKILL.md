---
name: repo-triage
description: Triage open PRs, issues, and Renovate Dependency Dashboards across GitHub repositories. Use when the user asks to check, review, or triage their repos, open PRs, pending updates, or dependency dashboards. Also use for phrases like "check my repos", "what needs attention", "any open PRs", "check renovate", or "what's pending".
---

# Repo Triage

Scan GitHub repositories for open PRs, issues, and Renovate Dependency Dashboards, then present a prioritised summary of what needs attention.

## Step 1: Determine scope

- **Own repos (default):** `thetillhoff` — use `gh repo list thetillhoff`
- **Contributing to others:** ask the user for the owner/repo list, or derive from local clones (`git remote get-url origin`)
- If the user specifies a subset (e.g. "just my Go repos", "just webscan"), filter accordingly

## Step 2: Get non-archived repos

```bash
gh repo list <owner> --limit 100 --json name,isArchived \
  --jq '[.[] | select(.isArchived == false) | .name] | .[]'
```

## Step 3: Check open PRs across all repos

```bash
for repo in <repo-list>; do
  prs=$(gh pr list --repo <owner>/$repo --state open --json number,title,author \
    --jq 'length')
  if [ "$prs" -gt 0 ]; then
    echo "=== $repo ==="
    gh pr list --repo <owner>/$repo --state open \
      --json number,title,author,labels \
      --jq '.[] | "#\(.number) \(.title) [\(.author.login)] \(.labels | map(.name) | join(","))"'
  fi
done
```

## Step 4: Check Renovate Dependency Dashboards

```bash
for repo in <repo-list>; do
  dash=$(gh issue list --repo <owner>/$repo --state open \
    --search "Dependency Dashboard" --json number --jq '.[0].number' 2>/dev/null)
  [ -z "$dash" ] && continue
  echo "=== $repo (issue #$dash) ==="
  gh issue view $dash --repo <owner>/$repo --json body --jq '.body' \
    | grep -E "^\s*- \[ \]" | grep -v "Check this box"
done
```

## Step 5: Categorise findings

Group everything into these buckets — act on high-priority items first:

### 🔴 High priority
- **Security PRs** — Renovate PRs with `[SECURITY]` in the title, or Dependabot security updates. Merge or review immediately.
- **Failing CI on open PRs** — check with `gh pr checks <number> --repo <owner>/<repo>`

### 🟡 Medium priority
- **"Configure Renovate" PRs** — PR #1 from `app/renovate` titled "Configure Renovate". Merge to onboard Renovate on that repo.
- **Dependabot PRs where Renovate is also active** — these are duplicates. Close the Dependabot PRs with: `gh pr close <number> --repo <owner>/<repo> --comment "Closing — Renovate handles dependency updates for this repo."`
  - Check for Dependabot being explicitly configured: look for `.github/dependabot.yml` or `.github/dependabot.yaml` in the repo
- **Major version PRs** (Renovate) — need manual review before merging
- **Lock file maintenance PRs** — usually safe to merge directly

### 🟢 Low priority / informational
- **Pending Approval items in Dependency Dashboard** — Renovate is holding these back. Since `dependencyDashboardApproval: false` is set across repos, these will auto-create PRs on the next scheduled Renovate run (every weekend). No action needed unless you want to unblock them now (check the checkbox in the issue body or comment).
- **"Awaiting Schedule" items** — will run on next scheduled Renovate run. No action needed.
- **Rate-limited PRs** (`<!-- unlimit-branch=... -->`) — Renovate is throttling these. Renovate will open them incrementally.

## Step 6: Present summary

Structure the output as:

```
## Repo Triage — <date>

### Needs action (<n> items)
- [repo] PR #N: <title> — <why it needs action>
...

### Informational
- [repo] N items pending in Renovate dashboard (auto-creates next weekend)
...

### Nothing to do
- repo1, repo2, ...
```

Then ask: "Want me to act on any of these?"

## Common actions

**Merge a PR:**
```bash
gh pr merge <number> --repo <owner>/<repo> --squash
```

**Close a Dependabot PR (duplicate):**
```bash
gh pr close <number> --repo <owner>/<repo> \
  --comment "Closing — Renovate handles dependency updates for this repo."
```

**Merge "Configure Renovate" PR:**
```bash
gh pr merge <number> --repo <owner>/<repo> --squash
```
Note: if the repo doesn't have auto-merge enabled, drop `--auto`.

**Check if Dependabot is active on a repo:**
```bash
# Check for explicit config file
ls .github/dependabot.yml .github/dependabot.yaml 2>/dev/null

# Check if automated security fixes are enabled
gh api repos/<owner>/<repo>/automated-security-fixes
gh api repos/<owner>/<repo>/vulnerability-alerts
```

**Disable Dependabot version updates** (when Renovate covers everything and security features are not needed):
```bash
# Remove the config file and commit
git rm .github/dependabot.yaml  # or dependabot.yml
git commit -m "chore: remove dependabot config in favour of renovate"
git push origin main
# Then close open Dependabot PRs
```
If security alerts/fixes are enabled and the user wants to keep them, leave the Dependabot config but add `open-pull-requests-limit: 0` to each ecosystem entry instead.

## Notes from thetillhoff's repo setup

- GitHub handle: `thetillhoff`
- Repos cloned to: `~/code/<repo-name>/` or `~/code/*/<repo-name>/`
- Renovate config pattern: `config:best-practices`, `automergeType: "branch"`, no `dependencyDashboardApproval`, schedule: every weekend
- Archived repos (skip): filter with `isArchived == false`
