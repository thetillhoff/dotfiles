# User CLAUDE.md

## Git

- Always use SSH URLs for `git clone`: `git@github.com:<owner>/<repo>.git` — never HTTPS.
- Repo layout: `~/code/<owner>/<repo>/` — `.git` may be at any subdirectory level within, not necessarily the root. Locate it before running git commands.
- Use `cd <path> && git <cmd>`, never `git -C <path> <cmd>`.
- Superpowers skills must never run git commands.
- **Start every new topic or feature from the latest upstream state.** Before you write code, run `git pull` on the current branch. Before you branch off `main`, check out `main` and pull it first. This prevents work that starts from a stale base.
- **Run `git branch --show-current` right before every commit.** Another process can switch the branch of the checkout during a session. A commit once landed on a feature branch of another task that way.
- **Another session can work in the same repo.** Run `git status` before a commit and stage by path, never `git add -A`: its uncommitted files are not yours. A session of the user (for example `mosswood-app-*`) committed its own work in the middle of this one.
- **Never pass a commit message with `git commit -m "..."` if it contains backticks.** The shell substitutes them and runs the contents as a command. A message containing the literal words `git add -A` executed exactly that, staging the whole repo into what should have been a five-file commit; another ran the test suite and pasted its output into the message. Always use a quoted heredoc, which substitutes nothing:

  ```sh
  git commit -F - <<'MSG'
  subject line

  Body may contain `backticks`, $VARS, and $(anything) safely.
  MSG
  ```

  The quoted `'MSG'` delimiter is what disables substitution; an unquoted `MSG` does not. Use the same form for `--amend`.

## Parallel Agents

- A hand-back can be interim: an agent that spawns helpers reports early, or repeats the same report many times. Do not trust a report. Check the tree: build, vet, tests, and a diff filter for the kind of change that was allowed. Stop a looping agent with `TaskStop`.
- Split bulk edits by directory, so no two agents touch one file. Tell each agent the checks to run and that it must not change state in git.

## Principles

- **DRY** (Don't Repeat Yourself) — one source of truth; extract only after 3+ identical uses, not before.
- **KISS** (Keep It Simple, Stupid) — simplest solution that works; never clever for clever's sake.
- **YAGNI** (You Ain't Gonna Need It) — don't build for hypothetical future needs; later can scaffold for itself.
- **SRP** (Single Responsibility Principle) — one unit does one job; split when a second unrelated reason to change appears.
- **CoC** (Convention over Configuration) — follow existing patterns before inventing new ones.
- **Fail fast** — surface errors at the boundary; don't swallow and continue silently.
- **Reference, don't restate** — in CLAUDE.md, AGENTS.md and skills, name a public standard, spec or well-known practice and stop. The next agent knows it as well as you do. Write down only what it cannot know: the choice between options, the exception, the project fact.

## Scope: Ask Before You Add a Feature

- Do only what the user asked. A new feature, mechanism or contract that the user did not mention is a separate decision.
- Ask before you add it. Examples: a version scheme, a new field, a new endpoint, a migration, a new dependency.
- A change that the user asked for can need such a part to work. Then name the part and ask, or take the smallest option and say so.
- Do not keep something just because the old code had it. If the user asks for a rewrite, ask whether the old extras stay.

## Version Numbers

- A version number counts releases, not iterations. Bump it once for a change that ships, however many drafts came before.
- An unreleased draft has no version of its own. Replace it in place: the newest draft is the current version, also when an earlier draft was committed, pushed or reviewed.
- Do not keep, number or describe earlier drafts in code or comments. Git history is the record.

## CLI Deprecation

- Do not add a forwarding stub for a removed subcommand or flag ("X moved to Y"). Delete the subcommand outright.
- Reason: a stub is legacy weight. It sits in the code forever and nobody prunes it later.
- If a codebase already has stubs like this, do not silently remove them. Flag them to the user first, so they know the weight exists and can decide.

## URL Deprecation

- Do not keep an old URL path alive after a rename or move. Delete the old route; an old link returns 404.
- No redirect, no alias route, no "kept for bookmarks" handler - unless the user explicitly asks for one.
- Reason: same as a CLI stub. A redirect is legacy weight that stays forever.
- A redirect that canonicalises a LIVE URL (two current ids for one resource) is not legacy. Keep it.

## Code Comments

Every comment is another thing to update, review, and re-read. A stale one is worse than none.

- Why, not what. Never restate the code, a name, or a flag.
- Two lines max. Longer than the code it explains means delete it or cut it.
- No war stories: no "we tried X", no measured timings, no quoted error text, no diff history. That goes in the commit message or `TODO.md`.
- Never reference another PR, issue, or ticket number in a code comment ("once PR #69 merges", "see issue X"). That's process metadata; it rots and means nothing to a reader without repo access. State the actual technical constraint instead: what's missing, what's unsupported, what the workaround compensates for.
- Prefer a better name. If renaming removes the need for the comment, rename.
- A non-obvious constraint (hardware quirk, API contract, workaround) earns one line naming the constraint - not the investigation behind it.
- `ponytail:` markers stay one line: the ceiling and the upgrade path.

## Research & Debugging Discipline

- **Falsification-first, not narrative-first.** Assume your latest result is wrong; try to break it before reporting. Don't build a story then defend it.
- **State conclusions with their confounds.** "X, but Y isn't controlled" — never bare "X" when a variable moved alongside.
- **Control the variable.** Two things changed together (e.g. a multiplier shifting both signal weight and total exposure) = you isolated nothing. Hold confounders constant.
- **Never write a parser or adapter against an invented fixture.** Capture one real payload from the live endpoint FIRST, commit it as the fixture, then write the code. A fabricated fixture makes every test compare the code against your own assumption, so no test can fail on the one thing that is wrong. Twelve passing reviews of a news-ingestion adapter missed that its source returns space-separated archive URLs, not tab-separated rows, and that the other source returns Atom, not JSON.
- **A surprising result is a measurement bug until proven otherwise.** Contradictions (0 trades + high exposure) → distrust the parse/instrument before the system.
- **Verify the premise before building the fix.** One cheap measurement of the real bottleneck beats a confident assumption. Never optimize an unmeasured cost.
- **Structured data → real parsers.** pandas for CSVs (fields contain commas); shell arrays for lists. Never `awk -F,` column-splitting; never unquoted `for x in $VAR` / `set -- $x` in zsh (it doesn't word-split — use `${=var}` or arrays).

## Scaffolding Over Manual File Creation

Prefer scaffolding commands (`npm create`, `cargo new`, `go mod init`, `docker init`, framework CLIs, etc.) over writing boilerplate by hand. Only write files manually when no scaffolding command covers it.

## Dev Environment

### Docker for Python and system-level runtimes

Always run Python in Docker - never install Python packages on the host. Node.js is exempt (dependencies go into `node_modules`). See the `dev-environment` skill for the full rule set and Docker command patterns.

### cd then command, never flag-based directory override

Always `cd <path> && <cmd>` — never use flag-based directory overrides like `git -C <path>`, `npm --prefix <path>`, or similar. The `cd` form matches shell allowlists; flag overrides do not.

### Text replacements: sed, not perl

For shell-based in-place text replacements, use `sed` — never `perl -pi`. (Prefer the Edit tool over both when editing a known file.)

### Granted/`assume`: never pipe it, always verify identity before an apply

`assume <profile>` is a shell function (`assume` is aliased to `. assume`) — it must run as a
plain foreground command in the current shell. Piping it into anything (`source assume ... |
tail -3`) forks a subshell for the piped side in both bash and zsh, so the exported
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN` never reach the parent shell —
the next command then silently falls through to whatever credentials were already in the
environment. A fresh non-interactive shell can already have stale `AWS_*` env vars baked in
from an unrelated SSO session (profile init, `.zshrc`, a leftover export) — those take
precedence over `AWS_PROFILE`-based resolution, so `AWS_PROFILE=x pulumi up` can silently run
under the wrong account with no error. Always run `source assume "<profile>"` unpiped, then
confirm with a plain `aws sts get-caller-identity` (also unpiped) immediately before any
command that creates, modifies, or destroys real infrastructure — not just once per session.

### Wrong AWS account: say it first, and only that

If something the user shows (a bucket name, an account ID, a resource that the repo does not
create) suggests that the AWS console or CLI is on another account than the repo uses, say so
at once, in one short message, and do nothing else. Example: "It seems you are not in AWS
account <id>. Can you double check?" Name the account that the repo expects. Do not read the
other project's code, do not explain the resources, and do not start work before the user answers.

### Git: cd then git, never git -C

Already stated above under Git. Repeated here as a reminder for hook sections below.

### Retrieving a command's return code

To get a command's exit status, run a plain `echo $?` on its own — not a per-command `echo "label: $?"` each time. If a label is wanted, print a static `echo` line right before it, never in the same command (a preceding command would overwrite `$?`).

### `docker exec` with a heredoc needs `-i`

`docker exec <ctr> python3 - <<'EOF'` without `-i` silently runs NOTHING: stdin
isn't attached, the interpreter reads EOF immediately and exits 0 with no output.
It looks like a script that produced nothing rather than one that never ran. Use
`docker exec -i <ctr> python3 - <<'EOF'`, and treat "no output at all" from a
heredoc as this bug until proven otherwise.
`kubectl exec` has the same trap: use `kubectl exec -i`.

### `docker run -v` needs `:z` on SELinux, and mount dirs not files

On this host (SELinux enforcing), `-v /path/script.py:/script.py:ro` fails with
`can't open file: [Errno 13] Permission denied` - the file has no container label.
Add `:z` to every bind mount, and prefer mounting the containing directory
(`-v "$DIR:/work:z"`) over a single file: relabelling one file is fussier and a
script usually wants siblings anyway.

### `/home` is a symlink to `/var/home` - tools that refuse symlinks break

On this host (Bazzite) `/home` points to `/var/home`. `@swc/core` (used by the
`cdk init` jest setup) then fails with `Failed to load native binding` /
`cache root contains a non-directory or symlink`. Set
`SWC_NATIVE_BINDING_CACHE=/var/home/$USER/.cache/swc` before `npx jest`.

### Pulumi CLI: default login is an S3 backend

The CLI on this host is logged in to an S3 backend. Without AWS credentials, `pulumi new` fails with `no EC2 IMDS role found`. Scaffold with `PULUMI_BACKEND_URL=file://~ pulumi new <template> --generate-only`. `@pulumi/pulumi` rejects TypeScript 7: install `typescript@5`.

### `pulumi import` protects the resource by default

`pulumi import` marks each imported resource as protected in the state, even when the code has no `protect`. Pass `--protect=false` when the project uses no protect flags.

### Taskfile: a shell variable wins over an `env:` block

Task lets a variable of the caller's shell override the `env:` of a task. An exported `PULUMI_BACKEND_URL` of one account then sends a task for another env to the wrong state bucket, with no error. Set such a variable on the command itself (`- VAR='{{.VALUE}}' cmd`), never in `env:`. A `vars:` map also rejects the YAML merge key (`<<: *anchor`): put every variable into the anchored map.

### `pkill -f <pattern>` kills its own shell

`pkill -f "node local/server.js"` also matches the Bash tool's own command line
(which contains that string) and kills it with exit 144 - every command after it
in the same call never runs. Stop a background server by its task id, or with
`pkill -f '[n]ode local/server.js'` so the pattern does not match itself.
The bracket form fails when the same call also holds the plain string (a
`pkill` and then a restart in one call). Stop and start in two calls.

### Playwright: Docker only

Never install a browser on the host. Use the `playwright-bazzite` skill for screenshots, scripted flows and the Playwright MCP.

### Kubernetes manifests: one resource per file

One k8s manifest per file - never bundle multiple resources with `---` separators. Name files `<kind>-<name>.yaml` (e.g. `serviceAccount-trading-worker.yaml`), matching the existing dir convention. Wire each into `kustomization.yaml`.

## Infrastructure as Code: never CloudFormation directly

- Never use CloudFormation directly. Do not write templates. Do not use L1 `Cfn*` resource constructs or `node.defaultChild` escape hatches. Do not build values from intrinsic functions or dynamic references (`{{resolve:...}}`).
- Exception: the project already uses raw CloudFormation. Then follow it.
- Otherwise use the IaC tool the project already uses. Use Terraform only when the project already uses it.
- For new infrastructure, use AWS CDK or Pulumi. Prefer TypeScript for both.
- If an L2 construct lacks a setting, look for another L2 construct first. Example: a `HttpStage` with `throttle` instead of a `CfnStage` override.
- Do not pass a secret value through the template. Grant the function read access to the secret and read it at runtime.

## Memory

Never write project-specific memory to `~/.claude/projects/*/memory/` — those files are machine-local and invisible to colleagues or other machines. Put project context in the repo's `CLAUDE.md` instead (checked in, portable, always present). The auto-memory system is fine for truly global preferences (user style, cross-repo workflow rules) but not for anything repo-specific.

## Finishing Work (leave it closeable)

End a piece of work with the repo in a state a fresh session could close - no implied follow-up:

- Update the docs the change touched: `README.md`, `EXAMPLES.md`, `TODO.md`, design/spec docs, and `CHANGELOG.md` if the repo keeps one. Don't touch docs the change didn't affect.
- Capture next steps and known gaps in `TODO.md` so nothing lives only in chat.
- A gap the user accepts (no fix planned) moves from `TODO.md` to `KNOWN-ISSUES.md`. `TODO.md` holds only work someone will do.
- Commit completed work with a written message; never leave a coherent change uncommitted or half-applied. (Push only when asked.)
- Write down anything deliberately deferred (a `TODO.md` entry or a `ponytail:` comment) instead of leaving it implicit.
- Persist all session learnings to files — never rely on memory. Each learning that's reusable across repos (a workflow rule, a tool quirk, a preference) goes in this global CLAUDE.md or a global skill; each one specific to a repo goes in that repo's `CLAUDE.md`, docs, or a repo-local skill. This means editing existing skills and CLAUDE.md sections, not just adding new ones — if a skill or CLAUDE.md section was wrong, incomplete, or out of date during the session, correct it in place before finishing. Treat "I'll remember this" as a bug: if it isn't in a file, it didn't happen.

Stop because the work is at a clean point, not because the turn ran out. If a follow-up prompt would obviously just be "now tidy up / update the docs / commit", do that now.

## Superpowers Workflow Hooks

### During superpowers:writing-plans

- Any task that runs, tests, or installs Python must specify Docker in the plan steps.
- All git commands in the plan must use `cd <path> && git <cmd>` — never `git -C`.
- **Check the plan's own code comments against ASD-STE100 before the plan ships.** Implementers copy plan code verbatim, comments included. A plan that mandates the standard while its own samples chain clauses with `and`/`but`/`so` produces one fix round per task. A 9-task plan spent 3 fix rounds on comments that were all plan text.
- **Check dependency edges, not just interface names.** Two tasks can agree on a signature while no task ever adds the dependency that makes it importable. A plan had `cli` calling `translate_core::Subtitle` and never added `translate-core` to `cli`'s manifest.

### During superpowers:subagent-driven-development

**Before dispatching any subagent**, include the full content of the `dev-environment` skill in the subagent brief. Subagents do not inherit CLAUDE.md — without this, they will use `pip install` on the host and `git -C`, breaking both constraints.

**On frontend tasks, rebuild and open the page in a real browser after each task** (playwright-bazzite, with a `pageerror` listener). Grep tests of templates and JS pass while a load-time error kills every handler after it. One such error left a whole tab widget dead under a green suite of 400 tests.

### During superpowers:test-driven-development

- Python tests must run inside Docker. Do not run `pytest` or `python -m pytest` directly on the host.

### During superpowers:systematic-debugging

- If debugging involves running Python, run it in Docker. Do not install debug deps on the host.

### During superpowers:executing-plans

- Apply the same Docker and git constraints as during writing-plans when executing steps.

## Answer Length

- Answer exactly what the user asked, and stop. A request for a command gets the command, with no explanation, no variants and no safety notes.
- Add details only when the user asks for them, or when a step can destroy data or cost money.
- Do not wrap a command in extra shell (`read -rs`, `unset`, pipes) unless the user asks. Leave a value the user must fill in as the last argument or as `<placeholder>`.

## Blog/Prose Writing Style

- No em dashes (—). Use a plain hyphen-minus surrounded by spaces ( - ) instead.

## Simplified Technical English (ASD-STE100)

Write all prose (docs, READMEs, specs, TODOs, design notes, code comments, commit bodies, PR descriptions, chat answers) in ASD-STE100 Simplified Technical English. It is a writing standard for technical text, not a style preference - a tired reader, a non-native reader, or a model must parse it correctly on the first pass.

- One word = one meaning = one part of speech. Pick a term, reuse it everywhere. Never swap synonyms for variety ("start" is not sometimes "launch", "kick off", "fire").
- Active voice. Name the actor: "The service writes the log", not "The log is written".
- Imperative for instructions: "Start the container." Not "The container should be started."
- Present tense for what is. Simple past or future when needed. No perfect tenses ("has been added" -> "exists", or delete it).
- One instruction per sentence. Split a compound instruction into two. Max 20 words per instruction, 25 per description.
- One paragraph = one topic, max 6 sentences. Use a vertical list instead of a long sentence.
- Only approved/technical vocabulary. Prefer: use (not utilize), start (not initiate/commence), do (not perform), about (not approximately), before (not prior to), after (not subsequent to), can (not is able to), must (not is required to), help (not facilitate), send (not transmit) - unless the long form is the exact technical term.
- No noun clusters longer than 3 words. Break with "of"/"for": "settings of the retry queue", not "retry queue settings configuration".
- No -ing verb forms as nouns or modifiers where a plain verb works. Use "to configure X", not "configuring X".
- Keep articles ("the", "a"). STE requires them.
- STE takes precedence over the caveman rules. Where the two conflict, follow STE: keep the articles, write full sentences, and drop no words that carry meaning. Caveman still applies to what you cut - no filler, no pleasantries, no hedging.
- Keep warnings and safety text before the step they apply to, never after.
- Say the outcome, not the exploration: "Cap the pool at 64", not "Look into whether we should maybe cap the pool".

Exempt: code, code identifiers, quoted error messages, external names, direct quotes, commit messages that follow another convention, and prose the user asked for in another register (a blog post, marketing copy).

## German: Regelbasiertes Schreiben (tekom)

Write all German prose by the tekom guideline "Regelbasiertes Schreiben - Deutsch für die Technische Kommunikation", the German counterpart of ASD-STE100. Spelling follows Duden. On top of it:

- Address nobody where the sentence allows it: no "du", no "Sie". If a form of address is needed, follow the one the project already uses.
- An instruction is "Bitte" plus infinitive: "Bitte erneut hochladen."
- The exemptions of STE apply. A legal text keeps the wording that a lawyer approved.

## Markdown Linting

**Always run markdownlint with `--ignore node_modules`** (global setting). A `**/*.md` glob otherwise lints dependency markdown and floods the output with errors you don't own.

**`--ignore node_modules` is not enough on its own - it matches only a top-level `node_modules`, not a nested one.** A monorepo with `services/frontend/node_modules` still floods. Keep a `.markdownlintignore` at the repo root (markdownlint-cli auto-respects it) listing `node_modules/`, `dist/`, and any directory of GENERATED markdown (`results/`, report output) plus gitignored scratch (`docs/superpowers/`). The goal is that `npx markdownlint-cli --ignore node_modules -- '**/*.md'` exits 0 over the whole repo, so a real violation is visible instead of buried.

After creating or editing any markdown file, auto-fix the mechanical issues first, then lint:

```sh
npx markdownlint-cli --fix --disable MD013 --ignore node_modules -- <file.md>
npx markdownlint-cli --disable MD013 --ignore node_modules -- <file.md>
```

`--fix` handles tables, bare URLs, list/heading spacing, etc. automatically. Fix any remaining reported errors (e.g. MD040 fenced-code language, which it can't infer) by hand before considering the task done.

**MD049/MD050 style is inferred from the first emphasis in the file, so one new `*word*` can fail every pre-existing `_word_`.** The errors point at untouched lines far from your edit and read like the file was already broken. Check the baseline before "fixing" them - `git show HEAD:file.md > /tmp/base.md` and lint that. If the baseline is clean, the offender is your own emphasis: match the file's existing style instead of letting `--fix` rewrite unrelated lines.

**`--fix` silently destroys tabs inside fenced code blocks (MD010).** Go, Makefiles, and Taskfiles all indent with tabs, so a markdown file that quotes them comes back with the indentation replaced by single spaces. Nothing warns you. In any repo whose markdown contains such code, add a `.markdownlint.json` at the root - markdownlint-cli auto-discovers it, and it also removes the need to pass `--disable MD013` on every call:

```json
{
  "MD013": false,
  "MD010": { "code_blocks": false }
}
```

Verify a config change actually took effect: run the lint with NO `--disable` flags and confirm it exits 0, then run `--fix` on a file with a tab-indented code block and confirm the tab is still there.

## Markdown Writing Style

When writing or editing markdown documents (READMEs, ADRs, design docs, architecture docs):

- **DRY** — Extract shared information into a single section and reference it. Don't repeat the same facts across options/sections.
- **Concise** — One sentence where one sentence suffices. No filler, no restating what the reader just read.
- **Diagrams over paragraphs** — Prefer diagrams to explain architecture, data flow, or component relationships. Always use Mermaid JS for diagrams in markdown files and READMEs (never ASCII art). Each node shows the component name and role on separate lines (e.g., `Kamailio\nSIP Registrar`). Include a color-coded legend inside the diagram (e.g., mermaid subgraph) only when connection types need explanation (e.g., solid = direct, dotted = indirect). The legend describes connection semantics, not components — components are self-described by their node labels.
- **Tables and bullet lists over paragraphs** — But only when they add clarity. Don't create tables or comparisons for the sake of it. Ask the user if unsure.
- **Per-option: only what's unique** — Shared traits go in a shared section. Each option describes only its delta.
- **Benefit over mechanic** — Say what a feature does for the reader, not incidental internals they can't act on (exact poll intervals, thresholds). State such a number once at its canonical spot, never repeat it.
- **Short advantages/disadvantages** — One line per point. No preamble.
- **Living lists use plain bullets** — `TODO.md`, backlogs, roadmaps, next-steps: unordered `-` only — never ordered `1. 2. 3.` and never checkboxes `- [ ]`. When an item is done, delete it; don't mark it complete or keep a "done" list (git history is the record). Adding/removing an item must not renumber or churn the rest. Ordered lists are only for genuinely sequential procedures where the numbers carry meaning.

## Skill Routing - UI/design cluster

Several skills overlap on UI/design work. Route by intent:

| Intent | Skill |
| -------- | ------- |
| Visual/aesthetic direction - new page, redesign, AI-slop audit | hallmark (also frontend-design) |
| UX principles + implementation craft (components, motion/animation, a11y, performance, responsive/mobile, color/theming), critique, operator/internal/admin tools | ui-ux-best-practices (absorbed operator-ui + interface-kit) |
| HTMX server-rendered patterns | htmx |
| Charts / data viz | dataviz |
| DESIGN.md spec documents | design-system |
| Verifying a built frontend - a11y scan, viewport sweep, keyboard path | frontend-verify |

If this cluster changes - a skill is added, removed, renamed, or merged - this table goes stale. Tell me so I can update it.
