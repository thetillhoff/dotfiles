# User CLAUDE.md

## Git

- Always use SSH URLs for `git clone`: `git@github.com:<owner>/<repo>.git` — never HTTPS.
- Repo layout: `~/code/<owner>/<repo>/` — `.git` may be at any subdirectory level within, not necessarily the root. Locate it before running git commands.
- Use `cd <path> && git <cmd>`, never `git -C <path> <cmd>`.
- Superpowers skills must never run git commands.
- **Never pass a commit message with `git commit -m "..."` if it contains backticks.** The shell substitutes them and runs the contents as a command. A message containing the literal words `git add -A` executed exactly that, staging the whole repo into what should have been a five-file commit; another ran the test suite and pasted its output into the message. Always use a quoted heredoc, which substitutes nothing:

  ```sh
  git commit -F - <<'MSG'
  subject line

  Body may contain `backticks`, $VARS, and $(anything) safely.
  MSG
  ```

  The quoted `'MSG'` delimiter is what disables substitution; an unquoted `MSG` does not. Use the same form for `--amend`.

## Principles

- **DRY** (Don't Repeat Yourself) — one source of truth; extract only after 3+ identical uses, not before.
- **KISS** (Keep It Simple, Stupid) — simplest solution that works; never clever for clever's sake.
- **YAGNI** (You Ain't Gonna Need It) — don't build for hypothetical future needs; later can scaffold for itself.
- **SRP** (Single Responsibility Principle) — one unit does one job; split when a second unrelated reason to change appears.
- **CoC** (Convention over Configuration) — follow existing patterns before inventing new ones.
- **Fail fast** — surface errors at the boundary; don't swallow and continue silently.

## Research & Debugging Discipline

- **Falsification-first, not narrative-first.** Assume your latest result is wrong; try to break it before reporting. Don't build a story then defend it.
- **State conclusions with their confounds.** "X, but Y isn't controlled" — never bare "X" when a variable moved alongside.
- **Control the variable.** Two things changed together (e.g. a multiplier shifting both signal weight and total exposure) = you isolated nothing. Hold confounders constant.
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

### Git: cd then git, never git -C

Already stated above under Git. Repeated here as a reminder for hook sections below.

### Retrieving a command's return code

To get a command's exit status, run a plain `echo $?` on its own — not a per-command `echo "label: $?"` each time. If a label is wanted, print a static `echo` line right before it, never in the same command (a preceding command would overwrite `$?`).

### Kubernetes manifests: one resource per file

One k8s manifest per file - never bundle multiple resources with `---` separators. Name files `<kind>-<name>.yaml` (e.g. `serviceAccount-trading-worker.yaml`), matching the existing dir convention. Wire each into `kustomization.yaml`.

## Memory

Never write project-specific memory to `~/.claude/projects/*/memory/` — those files are machine-local and invisible to colleagues or other machines. Put project context in the repo's `CLAUDE.md` instead (checked in, portable, always present). The auto-memory system is fine for truly global preferences (user style, cross-repo workflow rules) but not for anything repo-specific.

## Finishing Work (leave it closeable)

End a piece of work with the repo in a state a fresh session could close - no implied follow-up:

- Update the docs the change touched: `README.md`, `EXAMPLES.md`, `TODO.md`, design/spec docs, and `CHANGELOG.md` if the repo keeps one. Don't touch docs the change didn't affect.
- Capture next steps and known gaps in `TODO.md` so nothing lives only in chat.
- Commit completed work with a written message; never leave a coherent change uncommitted or half-applied. (Push only when asked.)
- Write down anything deliberately deferred (a `TODO.md` entry or a `ponytail:` comment) instead of leaving it implicit.
- Persist all session learnings to files — never rely on memory. Each learning that's reusable across repos (a workflow rule, a tool quirk, a preference) goes in this global CLAUDE.md or a global skill; each one specific to a repo goes in that repo's `CLAUDE.md`, docs, or a repo-local skill. This means editing existing skills and CLAUDE.md sections, not just adding new ones — if a skill or CLAUDE.md section was wrong, incomplete, or out of date during the session, correct it in place before finishing. Treat "I'll remember this" as a bug: if it isn't in a file, it didn't happen.

Stop because the work is at a clean point, not because the turn ran out. If a follow-up prompt would obviously just be "now tidy up / update the docs / commit", do that now.

## Superpowers Workflow Hooks

### During superpowers:writing-plans

- Any task that runs, tests, or installs Python must specify Docker in the plan steps.
- All git commands in the plan must use `cd <path> && git <cmd>` — never `git -C`.

### During superpowers:subagent-driven-development

**Before dispatching any subagent**, include the full content of the `dev-environment` skill in the subagent brief. Subagents do not inherit CLAUDE.md — without this, they will use `pip install` on the host and `git -C`, breaking both constraints.

### During superpowers:test-driven-development

- Python tests must run inside Docker. Do not run `pytest` or `python -m pytest` directly on the host.

### During superpowers:systematic-debugging

- If debugging involves running Python, run it in Docker. Do not install debug deps on the host.

### During superpowers:executing-plans

- Apply the same Docker and git constraints as during writing-plans when executing steps.

## Blog/Prose Writing Style

- No em dashes (—). Use a plain hyphen-minus surrounded by spaces ( - ) instead.

## ASD-STE100 Simplified Technical English

Write all prose (docs, READMEs, comments, commit bodies, PR descriptions, chat answers) in ASD-STE100 Simplified Technical English:

- One instruction per sentence. Procedures max 20 words per sentence, descriptive text max 25.
- One paragraph = one topic, max 6 sentences.
- Active voice. Name the actor: "The service writes the log", not "The log is written".
- Imperative for instructions: "Start the container." Not "The container should be started."
- One word = one meaning, one meaning = one word. Pick a term, reuse it everywhere. Never use synonyms for variety.
- Only approved/technical vocabulary. Prefer: use (not utilize), start (not initiate/commence), do (not perform), about (not approximately), before (not prior to), after (not subsequent to), can (not is able to), must (not is required to), help (not facilitate), send (not transmit) - unless the long form is the exact technical term.
- No noun clusters longer than 3 words. Break with "of"/"for": "settings of the retry queue", not "retry queue settings configuration".
- No -ing verb forms as nouns or modifiers where a plain verb works. Use "to configure X", not "configuring X".
- Do not drop articles ("the", "a") - ASD-STE100 requires them, unlike telegraphic styles.
- Keep warnings and safety text before the step they apply to, never after.

Exempt: code, code identifiers, quoted error messages, external names, direct quotes.

**Always run markdownlint with `--ignore node_modules`** (global setting). A `**/*.md` glob otherwise lints dependency markdown and floods the output with errors you don't own. Belt-and-suspenders: keep a `.markdownlintignore` at the repo root containing `node_modules/` and `dist/` - markdownlint-cli auto-respects it.

After creating or editing any markdown file, auto-fix the mechanical issues first, then lint:

```sh
npx markdownlint-cli --fix --disable MD013 --ignore node_modules -- <file.md>
npx markdownlint-cli --disable MD013 --ignore node_modules -- <file.md>
```

`--fix` handles tables, bare URLs, list/heading spacing, etc. automatically. Fix any remaining reported errors (e.g. MD040 fenced-code language, which it can't infer) by hand before considering the task done.

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

If this cluster changes - a skill is added, removed, renamed, or merged - this table goes stale. Tell me so I can update it.
