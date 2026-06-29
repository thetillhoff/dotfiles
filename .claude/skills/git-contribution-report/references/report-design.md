# Report design — contribution / customer-success

How to turn `analyze.sh report` JSON into a deliverable. Visual craft is
governed by the `artifact-design` skill; this file adds report-specific
structure, the qualitative layer, and framing.

## Two layers: counts + what was done

Numbers alone ("1,372 commits") answer *how much*, never *what*. A credible
report pairs them. Get the qualitative layer from the history itself:

- **Workstream purpose** — already in the JSON (`workstreams[].purpose`, from
  each repo's README). This is the cheapest "what": names the system each
  repo *is* (CMS, backup platform, firewall rules, messaging backbone).
- **Commit-message themes** — sample a person's or repo's subjects and cluster
  them into a few themes (features / infra / CI-CD / refactor / fixes /
  enablement). Use conventional-commit prefixes when present:
  ```sh
  cd <repo> && git log --all --no-merges --perl-regexp -i --author='<re>' \
    --format='%s' | sed -E 's/^([a-z]+)(\(.+\))?:.*/\1/' | sort | uniq -c | sort -rn
  ```
  And read the top ~30 raw subjects to name concrete deliverables in prose.
- **File-type / area mix** — what kind of work it was (IaC vs app vs config):
  ```sh
  git log --all --no-merges -i --author='<re>' --name-only --format='' \
    | sed -E 's/.*\.([a-z0-9]+)$/\1/' | sort | uniq -c | sort -rn | head
  ```
  `.ts/.yaml/.tf` → infrastructure; `.php/.js/.twig` → application; etc.

Write the "what" as one tight sentence per person and per workstream, grounded
in those samples — not vague ("various improvements") but concrete ("stood up
the TYPO3 site on AWS CDK, then the CMS messaging backbone on AmazonMQ").

**Describe the work, never assign a role.** Git tells you what someone
*touched*, not their job title, seniority, or remit. Labels like "full-stack
lead", "backend engineer", or "DevOps specialist" are inferences the data
can't support — one person may own a system, cover for someone, or commit
outside their actual role. Say what they built ("built the CDK deployment
pipelines and the AmazonMQ infra"), not who they are ("infra lead"). If a
person's real role matters to the report, ask the user — don't guess it from
commit patterns.

### Team/company aggregate ("what the engagement delivered")

Per-person "what" answers *who did what*; a customer also wants the
*person-agnostic* picture — what capabilities landed in their estate. Build it
by aggregating the whole team at once (join everyone's regex into one
`--author`):

- **Capability mix** — run the file-type and theme commands across the whole
  team, then map the raw counts onto capability buckets the customer
  recognizes, e.g.: `.ts/.hcl/.yaml` → *IaC & CI/CD*; `.php/.twig/.js/.scss`
  → *application/CMS*; subjects mentioning cloudfront/cert/dns → *edge &
  networking*; iam/nag/kms/policy → *security & governance*; backup/vault →
  *resilience*; datadog/alarm/monitor → *observability*; docker/ecs →
  *containers*; adr/docs + any workshop repo → *enablement*.
- Present as a short capability map (6-8 buckets), each one line naming what
  was delivered, ordered by weight. This is the spine of the company-level
  story; the per-person cards become the supporting detail.

Keyword theme counts are directional only (a word like "log" over-counts) —
use them to rank and group, not as headline figures. The file-type mix is the
more honest signal for *kind of work*.

## Structure

1. **Header** — engagement headline + the 3-4 exact aggregate numbers
   (commits, repos, months, share of estate).
2. **At a glance** — KPI strip of the rock-solid metrics.
3. **Who shipped what** — per-person card: numbers *and* a one-line "what".
4. **Workstreams** — table of repos with purpose, people, commits. This is the
   spine of the qualitative story.
5. **Delivery over time** — bar chart from `monthly_team`; call out the waves
   (onboarding spike, peak-delivery quarter) and tie each to what shipped then.
6. **Methodology footnote** — date, `git log --all --no-merges`, attribution by
   email, exclusions, the commits-vs-value caveat. This is what makes finance/
   procurement trust the rest.

## Framing for customer success

The reader is the customer (or an account lead reporting to them). Frame as
value delivered into *their* estate, not activity by an outside vendor:
"embedded for N months across N systems", "shipped X across the CMS, infra and
networking". Lead with breadth and continuity; let the per-person numbers
support, not dominate.

**Never overclaim the denominator.** A share like "15%" is only of the repos
you scanned, which skew toward repos the team worked on — so it overstates the
team's footprint across the customer's *full* estate, which you almost never
have. Don't write "X% of all development at <company>". Either scope it
explicitly ("X% of commits across the N repositories in this analysis") or drop
the percentage and lead with absolute counts and breadth, which need no
denominator. Same discipline for "N repositories": say "N repositories
analyzed", not "N repositories at <company>". Credibility with a customer dies
the moment they spot one inflated claim.

## Palette/type starting point (override per subject)

Cloud/infra subjects suit a cool slate-navy ground, a warm amber value-accent
(human delivery against cold infra), teal for positive deltas, metrics set in
a monospace face (console vernacular reinforces "hard numbers"), narrative in a
serif, structure in system sans. Don't reuse this for an unrelated subject —
re-derive from whatever the repos are actually about.
