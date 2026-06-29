---
name: git-contribution-report
description: >-
  Analyze and summarize git contributions across one or more repositories,
  attributing work to people even when they committed under several different
  names or email addresses, and turn it into a hard-numbers contribution or
  customer-success report. Use whenever the user wants to measure, quantify,
  summarize, or report on who did what across git repos — commits, lines
  changed, PRs/merges, activity over time — for a person, a team, a
  consultancy engagement, a performance review, or a "what did we deliver"
  writeup. Triggers on phrases like "analyze the git history", "how much did X
  contribute", "summarize what our team shipped", "customer success report
  from git", "contribution report", "who committed the most", even when the
  user doesn't name this skill.
---

# Git Contribution Report

Turn raw git history across many repos into credible per-person numbers, then
into a report. The hard part is **identity**: one person commits as
`alice@work.com` in repo X and `alice@personal.com` in repo Y — same person,
contributions must sum. This skill solves that with an explicit identity
config and a bundled script that handles the git/shell gotchas for you.

## Always use the bundled script

`scripts/analyze.sh` (pure bash + git, no Python/jq, macOS bash-3.2 safe).
Use it instead of hand-writing `git log` pipelines — it bakes in fixes for
the traps that silently corrupt ad-hoc attempts:

- **zsh expands `**`** before git sees it → the script runs `set -f` so
  exclusion pathspecs reach git intact.
- **`git --author` is a regex**; matching several emails needs alternation →
  the script always uses `--perl-regexp -i`.
- **`--numstat` parsing** must skip binary (`-\t-`) rows → `awk 'NF==3 && $1 ~ /^[0-9]+$/'`.
- **branch double-counting** → `git log --all` already de-dupes commits; no
  `sort -u` needed.
- **line-count inflation** from lockfiles, `cdk.out`, `vendor/`, `node_modules`,
  minified/binary assets → excluded by default (override with `$EXCLUDES`).

## Workflow

1. **Discover identities.** Run `analyze.sh list-authors <root>` to get every
   `Name|email` with counts. This is how you find a person's aliases — same
   human often appears as several rows (different names, `.ext` aliases,
   bot-free real addresses). Watch for distinct people who share a first name
   (`till.hoffmann` vs `till.kahlbrock`) — match on the discriminating part of
   the email, not the name.

2. **Write `people.conf`.** One `[Name]` block per person; under it, one
   author-match regex per line (matched case-insensitively against
   `Name <email>`). Group every address a person used:

   ```
   [Alice Smith]
   alice@work\.com
   alice@personal\.com
   [Bob Jones]
   bob\.jones
   ```

   Escape dots (`\.`) so `a.b@x.com` doesn't match `axb@x.com`. Confirm the
   identity grouping with the user before reporting — wrong grouping silently
   over/under-counts.

3. **Generate numbers.** Run `analyze.sh report <root> <people.conf>` → JSON
   with: per-person `commits / added / removed / merges / first / last / repos`,
   team `totals` (incl. `team_share_pct` = team commits ÷ all commits **in the
   scanned repos only** — see the scope caveat below before quoting it),
   `workstreams` (each repo's purpose + who touched it), and `monthly_team`
   activity for a timeline chart.

4. **Build the report.** For a plain answer, summarize the JSON in prose +
   tables. For a polished deliverable (customer success, exec summary, a page
   they'll share), read `references/report-design.md`, then build an Artifact
   — the global `artifact-design` skill governs the visual craft; the
   reference adds the report-specific structure and the caveats below.

## Caveats to surface in any report

Honesty keeps the numbers credible:

- **Scope is whatever repos were scanned — never "the whole platform".** The
  analysis only sees repos that happen to be present under `<root>` (usually
  the ones cloned locally), which skews toward repos the team worked on. So
  `team_share_pct` is *share within the analyzed repos*, not share of the
  customer's entire estate, and it is biased upward — the repos the team never
  touched are the ones most likely missing from the denominator. Never write
  "X% of all development at <company>" or "X% of the platform". Frame it as
  "X% of commits across the N repositories analyzed" and state which repos
  those are (or how many). If you can't enumerate the full estate, say the
  share is indicative, not authoritative. When in doubt, drop the percentage
  and report the absolute counts — those don't depend on a denominator.
- **Lead with commits, repos, span, merges** — these are exact (within the
  scanned repos). Treat line counts as directional: even with exclusions,
  vendored/generated code slips through and inflates large contributors.
- **Attribution is by author email**, so the report is only as right as the
  identity config. State the matching method.
- **Commits ≠ value** — a one-line critical fix and a 500-line refactor both
  count as one commit. Use commit counts to show *engagement and breadth*, not
  to rank people against each other.
- `merges` (merge commits authored) approximates PRs merged, but only when the
  team used merge-commit workflows; squash-merge repos undercount. Note it.

## Verify

`analyze.sh selftest` builds a throwaway repo where one person commits under
two emails and asserts they sum correctly. Run it if you change the script.
