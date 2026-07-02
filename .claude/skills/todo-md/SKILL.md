---
name: todo-md
description: Apply whenever creating, updating, or reading a project's TODO.md - and when the operator asks to "add this to TODO" or "capture as a follow-up". Enforces a per-topic headline layout, terse phrasing, an inline "Open questions" list per topic, and an "Options + Recommendation with reason" block for any live decision. Completed items are deleted, not marked done. Do NOT stage or commit TODO.md unless it is already tracked by git.
---

# Maintaining TODO.md

Living record of what's left. Not a changelog, not a history, not a to-do UI.

## Layout

- One file: `TODO.md` at the project root.
- Level-1 heading: `# TODO`.
- Each topic = one level-2 heading. No sub-topics unless a topic genuinely splits.
- Under each topic: plain `-` bullets. No checkboxes (`- [ ]`). No numbered lists unless the order is load-bearing.
- Standalone "Open questions" section only for questions with no topic home. Otherwise inline `**Open:**` bullets under the relevant topic.

Skeleton:

```markdown
# TODO

## <Topic name>

<One-sentence description of what this topic is about, as a plain paragraph.>

- **Ready to build.**   *(or)*   **Not ready:** <one-line blocker>
- <One-line item.>
- <Another item.>
- **Open:** <specific question that blocks the next step>?
  - **A:** <candidate answer>. <one-line trade-off>.
  - **B:** <candidate answer>. <one-line trade-off>.
  - Recommendation: **B**. <One-line reason.>

## <Next topic>

<One-sentence description.>

- ...
```

Every topic MUST start with a one-sentence description as a plain paragraph directly under the heading, before any bullets. The description names what the topic is - not how to build it, not why it's blocked. The reader should be able to skim topic titles + descriptions and decide which item to tackle next without reading the bullets. If you can't summarise the topic in one sentence, the topic is too broad; split it.

## Rules

- **Terse.** One line per bullet. No preamble. Fragments OK. Cut articles/filler.
- **On-point.** Describe the outcome, not the exploration. "Wire `video_compute_stats` writes." not "Investigate whether we can log timing metrics."
- **Completed items disappear.** Delete the bullet. Do not strike-through, do not move to a "Done" section. Git history is the record.
- **Open questions travel with the topic.** If a question is scoped to one topic, put it there as `**Open:**`. If it spans topics or has no home, put it in an "Open questions" section at the end.
- **Open questions are framed as questions with options, not open-ended prompts.** Every `**Open:**` bullet phrases a specific question (ending in `?`) and lists 2-4 candidate answers as one-level sub-bullets: `**A:** …`, `**B:** …`, `**C:** …`. Each candidate carries a one-line trade-off. When there's a clear best option, append a `Recommendation: **X**. <reason>` line beneath the candidates. This replaces free-form Opens - if you can only think of one candidate, the item is not an Open yet; either resolve it inline or ask the operator to elaborate. This subsumes the older stand-alone "Options & Recommendation" section; only promote to a top-level section when the decision spans multiple topics.
- **No dates unless they matter** (freeze windows, deadlines). Absolute date, not relative.
- **No assignees / owners.** This is not a ticket tracker.

## Definition of Ready

A TODO item is **Ready to build** when *all* of these hold:

- Every `**Open:**` bullet under the item's topic that blocks the design is answered. Non-blocking future questions can stay.
- The item can be described in a single design sentence, or a spec/design doc already exists.
- No pending question directed at the operator that hasn't been answered.
- If the item depends on another TODO (e.g. "requires `video_compute_stats` to exist"), that dependency is either done or explicitly marked as a prerequisite in the bullet.

Every topic in `TODO.md` must carry exactly one readiness marker as the first bullet under its heading, so the reader can see at a glance which items are actionable and which are still being defined. The marker is symmetric with `**Open:**`: same bold-label convention, same prominence.

- `- **Ready to build.**` - Definition of Ready fully met.
- `- **Not ready:** <one-line blocker>` - at least one condition unmet. The blocker line names *why* (e.g. "row shape needs an authoritative source of `encoding`", "waiting on operator's call between phash and learned matcher"). This is not a placeholder; if you write "Not ready" without a reason, you haven't identified the blocker yet - go find it.

Once you start the work, keep the `**Ready to build.**` marker until the item is completed and the bullet is deleted. Flip a topic from `Not ready` to `Ready to build.` only when *every* condition in the Definition of Ready is met - don't half-promote.

Do **not** start work on an item marked `Not ready`. Instead, surface the blocking questions (see the collaboration flow below) and wait for answers.

## Guiding design passes - one topic at a time

When the operator asks you to "guide through design passes" of `Not ready` items, or otherwise wants to promote items to `Ready`, work **one topic at a time**. Never dump the whole `Not ready` list at once.

**Per topic, in one reply:**

- Name the topic + its single-sentence description.
- List the blocking questions for THIS topic (as many as needed - one topic can have several).
- For each question: 2-4 candidate answers as sub-bullets with one-line trade-offs, plus a Recommendation when a clear default exists.
- Nothing about the other topics in the same reply.

**Then hand back and wait.** The operator's answers to this topic drive it toward Ready (or reveal that it needs a split). Only once the current topic is resolved (folded, marked Ready, or explicitly deferred) do you move to the next one.

**Why one-at-a-time:**

- A single Not-ready item can carry multiple weakly-related opens; forcing them into one bullet obscures the shape of the decisions. Multiple opens per topic is fine - they belong together.
- Fanning across topics in one reply floods the operator; a topic answered while a dozen others are unanswered creates half-committed state.
- If the operator wants a survey of ALL blocked items ("what's on the plate?"), give a one-line-per-topic index, then wait for them to pick which topic to walk. Don't preemptively expand every topic.

**Skip if the operator asked for a survey**, not a walkthrough. Surveys list titles + one-line blocker each. Walkthroughs go deep on one.

## When a topic gets too big or too mixed - split it

TODO topics rot in one of two ways. Both call for the same fix: **ask the operator to split**, don't silently absorb the growth.

**Signals that a topic is too big:**

- The one-sentence description no longer summarises everything under the topic. If you keep wanting to write "…and also X, Y, Z", the topic already contains X/Y/Z as siblings, not sub-items.
- The bullet list is longer than ~8-10 lines even after dropping filler.
- Multiple bullets contradict each other's assumptions (e.g. one bullet designs around a shared DB, another around a message queue - two topics wearing one hat).
- The Definition of Ready would need multiple independent Opens resolved before the topic is buildable, and those Opens are only weakly related.
- You catch yourself thinking "I'll ship half of this and follow up".

**Signals that a topic is mixed (operator drifted):**

- A single operator turn added bullets that touch different subsystems (e.g. "and while we're at it, also add X on the images page" landing in a topic about video overlays).
- The operator's `->` answer to an Open introduces a whole new feature idea instead of picking a candidate.
- The topic's title no longer matches half of its bullets.

**What to do when you notice either signal:**

1. Do NOT extend the topic further. Stop adding bullets in-place.
2. In your reply, name the split you're proposing: what stays in the current topic, what moves to a new topic (or a follow-up sub-topic), and why. Two to four proposed titles is usually enough.
3. Ask the operator to confirm the split before you rewrite TODO. Small phrasing changes don't need approval; a topic split does.
4. When they agree, do the split in one edit: keep the shared context in the parent topic, extract the sibling(s) as new top-level topics with their own one-sentence description and readiness marker. Re-evaluate the Definition of Ready on both halves - a split often unblocks one half by removing its dependency on the other.

If the operator says "keep it as one topic", trust them and stop nagging. The signals above are heuristics, not laws - but flag once so the choice is deliberate.

## Collaboration flow (operator ↔ assistant)

TODO.md is the shared queue. Updates ping-pong between the operator and the assistant:

1. **Assistant proposes** - adds items, adds `**Open:**` bullets for questions that block progress, adds `Options & Recommendation` for decisions with real trade-offs. Hands the ball back with a short summary of what's changed and what's blocking.
2. **Operator responds** - inline in `TODO.md`. Two conventions the assistant must recognise:
   - `-> <answer>` on the next line after a bullet: an answer or follow-up. The answer belongs to the bullet directly above.
   - New bullets or new topics the operator added directly.
3. **Assistant folds and hands back** - on the next turn the assistant must:
   - Delete each `**Open:**` bullet whose `->` answer is a resolution. Fold the resolution into the design bullets above so the answer becomes design, not history.
   - Convert follow-up questions from the operator (embedded in a `->` reply) into new `**Open:**` bullets when they still block progress; drop them if the assistant can answer inline.
   - Answer any question the operator directed at the assistant (`what do you think?`, `is this right?`) in the response text, and reflect the resolution in the file.
   - Re-evaluate the Definition of Ready for every touched item and update the **Ready to build.** marker.
   - Delete items the operator rejected or that are shipped.
   - Report back: what's now Ready, what's still open, what needs the operator next. Never leave `->` markers in the file after folding - the file is a live spec, not a chat log.

This ping-pong is the primary mechanism for turning fuzzy ideas into buildable items. Keep the file's bullets in "spec voice" - the `->` shorthand is transient scaffolding, not the record.

## Item lifecycle

A TODO entry is a placeholder for work. It moves through one of two flows before it's deleted:

**Well-understood work:**

```text
TODO → spec → implementation → docs
```

**Uncertain work (default when you can't answer the "Open" questions yet):**

```text
TODO → prototype → spec → implementation / refactor → docs
```

The prototype exists to answer the open questions cheaply. It doesn't need tests, docs, or polish. Once the prototype confirms the shape, throw it away or refactor it as you write the real thing.

Each arrow:

- **TODO → spec** - open questions are answered (`**Open:**` bullets emptied or moved to spec as decisions). Write the design doc (see below), commit it, then the TODO item points at the spec instead of restating it.
- **prototype step** - only for uncertain work. Ships to a scratch branch or a `spike/` directory. Not merged as-is.
- **spec → implementation** - build against the spec. If reality forces a change, update the spec, then the code.
- **implementation → docs** - touch every doc the change affects (README, EXAMPLES, CHANGELOG if the repo keeps one, spec/design docs). Don't touch docs the change didn't affect.
- **docs → TODO deleted** - the bullet is gone. Anything deliberately deferred is captured as a new TODO bullet or a `ponytail:` comment before the item is removed.

Which flow applies:

| Signal                                            | Flow                        |
| ------------------------------------------------- | --------------------------- |
| Requirements clear, tech familiar, cost bounded   | Well-understood             |
| Any `**Open:**` blocking the design               | Uncertain (prototype first) |
| Novel dependency or unfamiliar runtime            | Uncertain                   |
| Operator asked "will this even work?"             | Uncertain                   |

**With the superpowers plugin available**, the spec + implementation steps map to concrete skills:

- spec ← `superpowers:brainstorming` (saves to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
- implementation plan ← `superpowers:writing-plans` (saves to `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`)
- implementation execution ← `superpowers:subagent-driven-development` or `superpowers:executing-plans`
- prototype ← no dedicated skill; `superpowers:systematic-debugging` is the closest fit when the prototype is answering a "why doesn't X work?" question

**Without the superpowers plugin**, the same steps still apply but the artefacts land in whatever the project already uses:

- spec → `docs/`, `spec/`, `design/`, or an ADR folder - whichever exists in the repo
- implementation plan → inline in the spec, in the PR description, or a scratch note
- prototype → a scratch branch or a `spike/` / `sandbox/` directory
- docs → the same `README.md` / `EXAMPLES.md` / `CHANGELOG.md` this rule already governs

If none of those directories exist and the work is small, skip the spec artefact and go straight from TODO to implementation - but only when a single sentence in the TODO bullet is enough to describe the design. If you'd need a paragraph, write a spec.

## Adding items

- If the topic exists, append the bullet there.
- If the topic doesn't exist, add a new level-2 section. Place near a related topic; ordering isn't strict.
- If the item is a question, use `**Open:** <question>?` under the relevant topic, followed by 2-4 candidate answers as sub-bullets (see Framing Open questions above). A one-sentence Open with no candidates is not acceptable - if you can't imagine two plausible answers, the item isn't ripe enough to be an Open yet.

## Removing items

- The work is done → delete the bullet. If the section is now empty, delete the section.
- The item was rejected → delete it. The rejection lives in git history / conversation, not the TODO.

## One branch per topic

When you start work on a TODO topic - especially when running unattended across several topics in a row - do the work on a dedicated branch, merge it back to local `main` before starting the next topic, then delete the branch. This bounds blast radius: a failed or half-finished topic never blocks the next one, and the operator can always rewind a single feature without touching the rest.

Concrete flow per topic:

```bash
cd <repo> && git checkout main && git pull --ff-only          # baseline
cd <repo> && git switch -c topic/<short-slug>                  # dedicated branch
# ... implement, commit as normal ...
cd <repo> && git checkout main
cd <repo> && git merge --no-ff topic/<short-slug> -m "merge: <topic name>"
cd <repo> && git branch -d topic/<short-slug>
```

- Use `--no-ff` so the merge commit records the topic boundary in `git log`; a fast-forward hides it.
- Merge only when the topic is finished OR the operator says to stop; a Not-ready-mid-flight topic stays on its branch until they decide.
- Never push a topic branch unless the operator asks (`git push` remains a manual, deliberate action).
- Don't rebase - a merge commit per topic is the point.
- If a topic turns up a blocker mid-flight and you have to move on, commit what you have, note the blocker in TODO, leave the branch as-is (don't merge partial work), and start the next topic from `main`. The operator can pick the branch back up when the blocker resolves.

## Git behavior

Before staging or committing TODO.md:

```bash
git ls-files --error-unmatch TODO.md 2>/dev/null
```

- Exit `0` → tracked → OK to `git add TODO.md` and include in a commit.
- Non-zero exit → untracked → **do not** add or commit. Leave it working-tree-only. The operator decides when to check it in.

Never create a commit whose only purpose is TODO.md churn *and* whose TODO.md wasn't already tracked. Bundle the update into a commit alongside the code change that motivated the entry, or skip the commit entirely.

## When not to write to TODO.md

- Ephemeral chat context ("remember to test this later this turn"). Use a task tool instead.
- Rules / conventions / architecture. Those go in CLAUDE.md, ADRs, or design docs.
- Bug tickets with reproduction steps. Those go in the issue tracker if the project has one.

## Anti-patterns

- Prose paragraphs. Bullet or it doesn't belong.
- "Nice-to-have" as a dumping ground. Fold items into the topic they belong to.
- Sub-bullets deeper than one level. If a bullet needs a sub-list, it's probably its own topic.
- "TODO: think about X". Either it's an open question (`**Open:**`) or it's an action item. Pick one.
- Committing an untracked TODO.md as a side effect of another change.
- Starting work on an item that isn't Ready. Ask, don't guess.
- Leaving `->` reply markers in the file after folding the operator's answer. Fold and delete.
- `**Open:** <one-sentence question with no candidates>`. Every Open must ship with candidate answers.
- A topic heading with no one-sentence description underneath. The description is the topic's elevator pitch; without it the reader has to read every bullet to know what the topic is.
