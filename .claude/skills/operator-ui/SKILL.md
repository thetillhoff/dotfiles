---
name: operator-ui
description: |
  Design + implementation guidance for internal operator tools / control
  panels / admin UIs — interfaces whose metric is decisions-per-minute,
  not delight-per-pixel. Trigger when the user is building or refining
  any UI for a single-operator workflow: queues to triage, dashboards,
  back-office tools, ops consoles, admin panels, ETL/job runners,
  review queues, server-rendered HTML + HTMX setups, "internal tool",
  "admin UI", "control panel", "back office".
  Pair with frontend-design / interface-kit for marketing or product
  UIs — this one is specifically tuned for the dense-table, server-
  rendered, keyboard-first flavour. Lots of overlap with interface-kit;
  this skill adds the operator-specific judgement calls (table over
  card, density over whitespace, server-rendered over SPA, etc.).
---

# Operator UI

An operator tool is not a marketing site. The metric is
**decisions per minute** — how fast the operator gets through the
work the system has surfaced. That changes a lot of the usual
advice. Density beats whitespace. Speed beats fanfare. The page
should feel like a control panel, not a brochure.

## Real-time feedback / interactivity

A button that fires a long job replaces its label with a spinner +
a present-progressive verb. No trailing ellipsis — the spinner is
the "still working" signal; the word names the work.

- Simple example: `Scan` → `<spinner> Scanning`
- Complex example: `<spinner> Retrieving data` → `<spinner> Analysing`
  → `<spinner> Writing output`

A button that fires a long job replaces itself with a progress
indicator (spinner + percent + X/Y + current item) and restores
itself on completion. Never leave the operator staring at a frozen
page wondering if they double-clicked.

Same principle:

- Polling widgets (1–2 s polls) for anything long-running: job
  progress, services status, host load. They tell the operator
  nothing is stuck.
- Optimistic actions return a toast with the exact mutation in
  plain English so the operator can undo manually if needed. Name
  the actual entities ("merged track #5 into #3"), not "Success".

## Design system

Pick one and apply it uniformly. Fonts, sizes, corners, borders,
navbar, tables, colours — every subpage shares the same vocabulary.

Concrete defaults to lock in:

- **Spacing scale**: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px. Every
  padding, margin, gap is a multiple of 4.
- **Type scale**: 12 / 14 / 16 / 18 / 24 / 32. Never reach for an
  intermediate size.
- **Two font families**: a proportional face for prose + UI labels;
  a monospace face for paths, hashes, IDs, and numeric data that
  changes (tabular figures).
- **Concentric border radius** on nested rounded elements: outer =
  inner + padding. Skip this and inner cards look bloated.
- **Two state palettes**: one for product states (analysed / new /
  failed / running), one for traffic-light pills (red / amber /
  green at agreed thresholds). Both used consistently.
- **No information conveyed by colour alone**: pair every pill with
  a label or icon — numbers are the truth, colour is the
  at-a-glance aid.

## Information density

Pack the page.

- Tables, not cards, for repeating rows of structured data.
- Cards only when the row has visual content the eye actually scans
  (thumbnails, mini-charts, photos).
- Multiple pieces per row: short label + value + state pill + tiny
  action group. Whitespace inside a row is wasted scrolling.
- Group by what the operator triages by, not by table layout.

## Action vocabulary

Words in the UI are design material. Be consistent:

- Action buttons use the verb of what they do. Button says
  "Merge"; resulting toast says "Merged X into Y." The flow reads.
- Destructive actions name the target. Not "Delete" — "Delete
  person Y (3 samples)".
- Names of entities (track, scene, person, source) stay the same
  across pages. No synonym pile.
- Labels describe the concept, not the value. "Status: Disabled" reads
  cleanly; "Enabled: Disabled" is a contradiction. Pick a label that
  stays true for all possible values of the field.
- Empty states are short, useful sentences ("No proposals at the
  current threshold. Lower the slider or scan more files."), not
  decoration.

## Keyboard-first

Every routine action (merge, move, next, previous, reject, jump)
has a single-key shortcut. The mouse is for spot-fixes. Tab order
matches reading order. Focus ring visible — never strip it without
replacement.

**Exception: non-reversible actions** (delete, clear, drop) never
get a bare single-key shortcut. They go through a confirm prompt
that names the target, or sit behind a modifier chord. Reversible
actions live on the hot path; destructive ones live one extra step
away.

## Accessibility floor (non-negotiable)

- Contrast: 4.5:1 for normal text, 3:1 for large/labels. Verify in
  both schemes if a dark mode exists.
- Semantic HTML before ARIA. A `<button>` gives keyboard handling +
  focus + screen-reader role for free; a clickable `<div>` gives
  none of that.
- `prefers-reduced-motion` reduces durations to ~0 while keeping
  opacity/colour feedback (which is feedback, not decoration).

## Motion budget

High-frequency actions get no animation; rare actions can afford
it.

| Element | Duration |
|---------|----------|
| Hover, focus ring, button-press | ≤100 ms or none |
| Dropdown, popover, in-place HTMX swap | 150–250 ms |
| Polling refreshes | replace the fragment in place — no fade-in, no slide |
| First-time onboarding / celebration | only if it helps the operator notice something they'd otherwise miss |

`transition: all` is banned. Always specify what transitions.

## Server-rendered first

Default to server-rendered HTML + HTMX partials. No SPA unless the
data model demands it. The page renders fully without JavaScript
except for the live-polling widgets. Reading View Source is enough
to understand the page.

Patterns to keep using:

- `?v=` cache-buster on the main stylesheet whenever the file
  changes.
- Forms post to a route that returns one of: `HX-Redirect` (full
  page change), `HX-Refresh` (re-render current page), or a partial
  fragment that swaps in place. Pick one per action and stick to it.
- Confirmation via `hx-confirm` for any destructive action.
- A canonical nav + a host/process status widget pinned to the
  right.

**HTMX gotcha — preserve animated elements across swaps.** If a
spinner sits inside a polled fragment, every poll replaces the DOM
node and restarts its CSS animation. Either move the spinner
outside the polled element, OR add `hx-preserve="true"` + a stable
`id` so HTMX keeps the existing node when it swaps.

## What to avoid (AI-slop tells)

Operator UIs are easy to ship as the generic "AI" look. Don't.

- No purple-to-blue gradients on white. Pick a palette grounded in
  what the data actually is.
- No "Welcome back!" greetings. The operator is at work.
- No engagement-bait copy ("What do you think?"). State facts.
- No "AI-generated" feel from layout: every cluster of cards
  identical, every section the same three buttons, every empty
  state the same illustration + three-line paragraph.
- No false ranges in labels ("0 to ∞ tracks"). Concrete numbers or
  none.

## Progressive enhancement, not progressive degradation

The server renders a fully working page first. HTMX layers
live-polling, in-place updates, and partial swaps on top. If
JavaScript fails, the operator can still see + navigate everything;
they just lose the live feedback.

## Self-review before shipping a page

- [ ] All routine actions have a keyboard shortcut.
- [ ] Tab order matches visual order. Focus ring visible.
- [ ] Every row's state is legible without hovering or clicking.
- [ ] Counts in headings match what the table actually contains.
- [ ] Long jobs spawn a progress widget; the button doesn't lock
      silently.
- [ ] Confirmation prompts name the actual target ("Merge track #5
      into the previous track?" not "Confirm?").
- [ ] Empty / loading / error states styled the same as success
      states — not bolted on after.
- [ ] `prefers-reduced-motion` reduces durations to ~0.
- [ ] No `outline: none` without replacement.
- [ ] No information conveyed by colour alone.
- [ ] Durations rendered human-readable (`3m 4s`), not raw seconds.
- [ ] Polled-fragment swaps don't restart animations on stable
      elements (spinner, progress bar) — use `hx-preserve` or move
      them outside the swap target.

## When in doubt

Two questions, in order:

1. **What is the operator trying to decide on this row?**
2. **What's in their way?**

Everything that doesn't help answer (1) is a candidate for
deletion. Anything that gets in the way of (2) — extra clicks,
scrolling, ambiguous labels, slow polls — is a regression no
matter how it looks.
