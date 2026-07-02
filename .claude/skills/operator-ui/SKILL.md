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

### Failure banner sits with the progress widget

For any entity that runs through a backend pipeline, the detail
page shows the *latest pipeline state* at the top: a polled
fragment that renders one of three things — a "running" header
with the active stage + elapsed time, a red banner with the error
+ a re-run button on the last failure, or nothing when idle and
healthy. The polled query points at the same per-source job log
the queue writes to. Don't bury failures on a "scan" page; the
operator opened the detail page because something looked wrong.

### Show the active stage, not a fallback apology

When a multi-stage pipeline can't report fine-grained progress for
the current stage (e.g. face-matching emits no per-frame counts),
display just the stage name + elapsed time. Don't write "worker
hasn't reported per-frame progress yet" — that reads as
malfunction. Absence of a progress bar with a named stage already
means "this stage is opaque".

### Pipeline snapshot: prefer the stage with real progress

If multiple services hold the same source in flight (a dispatcher
+ the worker doing real work), the dispatcher's `current_jobs`
entry has no `detail` payload. Don't return the first match —
return the one whose `detail` carries the metric you want to show
(`frames_done`, `bytes_uploaded`, …). The dispatcher being "busy"
isn't what the operator wants to read.

### Spinner that survives polling

A CSS `@keyframes` spinner restarts to 0° every time HTMX (or any
poll-driven swap) replaces an ancestor element — even with
`hx-preserve`, because the inserted node is a fresh DOM element and
CSS animations are per-element. The result is a "frantic restart"
loop that looks like the spinner is racing.

Drive rotation from a single global `requestAnimationFrame` tick
instead. The tick reads `Date.now()` each frame and writes the same
`transform: rotate(deg)` to every `.spinner` in the document. Freshly
inserted spinners pick up the current phase on the next frame, so
there's no visible reset. Anchor the rotation to wall-clock time
(`(now % period) / period * 360`), not to the element's lifetime.

```html
<script>
(function () {
  const PERIOD = 1500;
  function tick(now) {
    const deg = ((now % PERIOD) / PERIOD) * 360;
    const els = document.getElementsByClassName('spinner');
    for (let i = 0; i < els.length; i++) {
      els[i].style.transform = 'rotate(' + deg + 'deg)';
    }
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
})();
</script>
```

`getElementsByClassName` returns a live HTMLCollection, so the loop
costs nothing. The CSS class keeps the size + border styling but
drops the `animation: spin …` line. This generalises to any indicator
whose phase you want continuous across server-rendered swaps.

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
- **Tooltips on every badge, pill, and computed metric**: any
  abbreviated label, colour-coded chip, percentage, score, or
  short status word gets a `title="…"` (or equivalent) that
  spells out what it measures and how to read it. If the operator
  has to ask "what does this number mean?", the UI failed. Rule
  of thumb: if you couldn't show this value with the legend cut
  off, it needs a tooltip.
- **One formatter per unit, used everywhere**: time → `humantime`
  (`3h 02m 04s` / `5m 12s` / `42s`), bytes → `humansize`
  (`B / KB / MB / GB`, 1 decimal), counts always tabular-numbered,
  paths shown via `<code>` with the same `--f-mono` face. Raw
  seconds, raw bytes, ad-hoc `"%.1f KB"` formatting anywhere in
  templates is a bug — the operator builds muscle memory for the
  shape "104.6 MB" and a stray "107124.7 KB" stops the eye.
- **Auto dark mode by default**: ship `prefers-color-scheme:dark`
  from day one. Define colour tokens at `:root` for light, then
  override the same tokens inside
  `@media (prefers-color-scheme: dark) { :root { … } }`. Set
  `color-scheme: light` / `dark` on `:root` so native controls
  (scrollbars, form widgets, dialogs) follow the theme. Spacing,
  type scale, and radii stay shared across modes — only the
  colour palette swaps. Retrofitting dark mode later is far more
  work than building both at once.

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

- Forms post to a route that returns one of: `HX-Redirect` (full
  page change), `HX-Refresh` (re-render current page), or a partial
  fragment that swaps in place. Pick one per action and stick to it.
- Confirmation via `hx-confirm` for any destructive action.
- A canonical nav + a host/process status widget pinned to the
  right.

### Static-asset cache buster: hand-bumped integer

Browsers cache `style.css` (and any other static asset linked from
the base template) aggressively. Without a buster, a CSS change
ships to the server but operators keep reading the old colours,
old layout, old spacing for hours — and the bug report you get is
"the page looks broken" with no obvious cause. Worse during a
dark-mode rollout: half the operators see white text on white
background and assume the deploy failed.

Use a hand-incremented integer in the URL:

```html
<link rel="stylesheet" href="/static/style.css?v=15">
<script src="/static/htmx.min.js"></script>
```

Bump `v=` every time the file changes. A monotonically-increasing
integer beats automated content hashes for this workflow:

- One line in `base.html`. No build pipeline, no manifest, no
  hash computation. Works the moment you add it.
- The number tells you *at a glance* how many style revisions
  this codebase has seen.
- When an operator says "the page looks broken", you can ask
  "what does View Source say after `style.css?v=`?" — if their
  number is behind, hard-refresh and you're done. No hash diff
  to read.
- Every PR that touches `style.css` also bumps the buster — easy
  rule, easy to check in review.

Apply the same buster to any other asset you change in lockstep
(a small `app.js`, etc.). Don't bother for vendor files that don't
change.

### Spinner across polled fragments — wall-clock-anchored tick

Mentioned in the dedicated section under Real-time feedback, but
worth listing here as a server-rendered pattern: any element with a
CSS animation that sits inside (or near) a polled fragment will
restart every poll, even with `hx-preserve`. Drive the animation
from a single global `requestAnimationFrame` loop in `base.html`
that reads `Date.now()` and writes `transform: rotate(deg)` to
every `.spinner` element. Anchored to wall-clock time, freshly-
inserted spinners pick up the current phase on the next frame, so
no visible reset. CSS keeps the spinner's *appearance* (size,
border, color); JS owns its *motion*.

**Form POSTs need a real redirect, not just `HX-Redirect`.** If a
form is submitted as a plain `<form method="post">` (no `hx-post`),
the browser navigates to the action URL and renders whatever it
returns. An empty body + `HX-Redirect: /elsewhere` is invisible to
the browser — the operator lands on a blank page. Return a `303`
redirect (or render a full page) for any handler that might be
reached without HTMX. `HX-Redirect` is only safe on handlers that
**only** receive HTMX requests.

**Spinner across polled swaps.** See the dedicated section under
Real-time feedback. CSS keyframes restart on every swap even with
`hx-preserve`; drive rotation from a single global rAF tick instead.

## Media with analytics — unify the scrubber

Pages that pair a media element (video, audio, log scrub) with
layered analytics (scene cuts, tracks, error markers, …) almost
always render *two* timelines on top of each other: the native
browser scrubber inside the `<video>` element + a custom timeline
below. They never line up. The native control has its own padding;
the custom timeline has lane labels on the left; pixels drift.

Don't fight it. **Hide the native control and make the custom
timeline the seekbar.** One physical timeline, one set of
geometry. Patterns:

- Drop the `controls` attribute on the media element. Render a
  small custom row above the lanes: play/pause button, monospace
  time display (current / total), tiny hint about where to click.
- A vertical playhead line absolutely positioned over all lanes,
  `left: (currentTime / duration * 100%)`, updated on `timeupdate`.
  Position uses the same `.lane-area` width the bars use, so
  alignment is by construction.
- Bars seek to their start time on click. Empty space in any lane
  seeks to the click's relative X. Both work, both feel natural.
- `Space` toggles play/pause when focus isn't in a text field.
- Drop the lane-label column. Put a tiny caption above each lane
  instead — bars now span 100% width, which is the only way to
  match the player's spatial timeline.
- Overlay a live state badge on the player itself ("Scene #N · 0s
  → 18m"), updated on `timeupdate`, pulsing briefly on every
  transition. Anchors context the operator otherwise has to find
  by scrubbing.
- The playhead line must be **grab-able**. mousedown captures,
  mousemove updates `currentTime`, mouseup releases. Pause during
  drag, resume if was playing. CSS transition off while
  `.scrubbing` class is set so the line tracks the cursor without
  lag. Add a wider invisible hit zone via `::after` (about 14px
  total) so the operator doesn't have to land on a 2px line.

When the timeline carries both informational lanes (immutable
data) and clickable controls (jump-to, merge, split), the
controls live next to the data they act on — not in a separate
action bar that the operator has to track back to the right row.

## Tunable algorithms in the UI

If the analytics pipeline behind the page has tunable parameters
(detector thresholds, model temperatures, clustering radii), put
them in a collapsible panel on the entity's detail page. Don't
hide them in env vars or admin scripts.

- One row per algorithm with an enable checkbox and `<input
  type="range">` sliders for each tunable, plus a live `<output>`
  driven by `oninput` so the operator sees the value while
  dragging.
- "Apply" runs the cheapest possible recomputation — never a
  full re-analysis if only one stage's parameters changed.
- Saved state lives at *three* levels: per-entity override (JSON
  on the row) → global default (`settings` table) → hardcoded
  fallback in code. The same form renders on `/<entity>/<id>` and
  on `/settings`; the only difference is the form action.
- Spell out the trade-off each detector makes ("HSV diff — best
  for hard cuts, misses dissolves") next to its row, not in
  external docs.
- When Apply lands and rebuilds derived rows, warn about the
  collateral damage in the button hint ("operator scene merges
  are lost on re-detect because scene ids change"). Don't make
  this discoverable by surprise.

### Tuning UI: drag + type + reset, every knob

Every tunable slider gets three affordances side by side:
- `<input type="range">` carries the form `name` — drag for coarse
  motion.
- `<input type="number">` (unnamed, JS-mirrored) for typed values
  when the operator knows the exact target. Bidirectional via
  `input` events; only the range submits, so the form still sends
  one value per knob.
- `↺` reset button restores `input.defaultValue` — the value at
  page load, the operator's mental anchor for "undo my tweaks
  since I opened this page". Not zero, not the global default.

Pick slider ranges generous enough to cover the metric's natural
domain. A slider capped at 100 for a metric that ranges 0–255 is
a bug — the operator hits the wall and can't reach the value they
need. When unsure, set the range from the actual observed extreme
× 1.5.

### Cache the expensive metric once, recompute composition live

Pattern for live-tunable analytics: separate the **feature
extraction** (expensive, one decode pass, depends only on the
source) from the **scoring composition** (cheap, depends on
operator knobs).

- First Apply runs the heavy pipeline once, writes per-frame
  metric arrays to a sidecar (`db/<feature>/<sha>.csv` is fine —
  inspectable, no schema migration needed).
- Subsequent slider drags re-run only the cheap composition (sum,
  threshold, weighted combine) against the cached metrics. Pure
  JS for the live preview, server-side for the canonical commit.
- Share the formula between client and server. Both compute the
  same number so what the operator sees is what Apply persists.
  Forking the math is how you discover a bug 30 commits later
  when the operator says "the preview lied".

### Live preview must rAF-throttle

Slider `input` events fire many times per second during drag. If
the redraw is non-trivial (compute signal across N frames, build
SVG path string, recount buckets), the chart stutters and feels
like the slider is fighting back. Wrap the redraw in a
`requestAnimationFrame` guard — at most one redraw per frame,
regardless of how fast the slider moves. The math runs the same
number of times either way; the DOM update doesn't.

### Live estimate of what Apply will produce

While the operator is tuning, show the result-count next to the
controls (`8 scenes (3 empty pruned) · 45 tracks`). Compute it
from the same live formula the chart uses. Operators tune more
confidently when they can see "this many records will land in the
DB" before they commit.

### Display caps separate from detection caps

When a single outlier compresses a metric line into a flat band,
operator can't see the signal. Add per-chart **display** min/max
sliders that clip the rendered line without affecting the
underlying data or detection. Detection still reads the full
signal — only the visualisation is clipped.

### Trigger modes for plateau-shaped signals

For metrics that sit at one level for a while, then jump to
another level (`average_rgb`, audio loudness), no static
threshold draws a useful line. Offer **`level` vs `delta`** mode
per detector:
- `level`: contribution = `max(0, value − threshold)`.
- `delta`: contribution = `max(0, |value[i] − value[i−N]| −
  threshold)`. The slider becomes "minimum jump to count"; an
  extra window-size slider (frames) controls smoothing.

Default to `level` — only flip on for detectors where the metric
type calls for it.

### Library-output column names: match by prefix

When a third-party library writes per-frame metrics that include
its own parameters in the column name (`adaptive_ratio (w=2)`,
`hash_dist [size=16 lowpass=2]`), look them up by prefix, not
exact match. Hardcoding the full name silently breaks the moment
the library default changes or you tune a sibling parameter.

## Backend state surfaces on the status page

When the backend supports states beyond up/down (draining,
restarting, paused, version-mismatched, queue-saturated), the
status page shows them explicitly. A draining service that still
answers `/status` with `draining: true` reads as a yellow
"draining" pill, not as "OK" (lying) or "unreachable" (also
lying). Operators triage off this page; ambiguity costs minutes.

## Bulk actions: primary + destructive in one row, counters in lockstep

When a list page supports both a non-destructive bulk verb (re-run,
re-analyse, requeue) and a destructive one (delete), they sit in
the same toolbar with the same checkbox set:

- Primary action on the left, destructive on the right.
- One counter per button, updated together by a single change
  listener. Both buttons disabled until at least one row is ticked.
- `hx-post` lives on each button so they hit different endpoints
  with the same form data. The `<form>` itself has no action.

## Selectable list with mixed row states

For a list where some rows are already done and the operator picks
which of the remaining ones to act on (scan-and-analyse, retry-
failed-only, requeue-pending), use a mixed checkbox column rather
than separate tables or a filter dropdown:

- **Done rows** render a non-interactive glyph (`✓` in the
  state-ok colour). Do NOT render a disabled checkbox — disabled
  controls look like "you forgot to fix this" and invite clicks
  that do nothing.
- **Actionable rows** render a real `<input type="checkbox">`
  **default-checked**. The operator's job is to *trim*, not to
  opt in row by row.
- **Header-row checkbox** toggles every actionable row at once.
  Maintain the three states: all-checked, none-checked,
  `indeterminate` for partial. A single change listener keeps the
  header in sync with the bodies.
- **Live counter** in the action button: "Analyse 7 of 23 new
  files" tracks selection. Button disabled when count is 0.
- **`form="…"` attribute** lets the checkbox inputs live inside
  the data table while still posting through a form rendered
  elsewhere on the page. No need to wrap the table in `<form>` or
  duplicate the data row markup.
- **Backend validates submitted keys against the live truth**.
  Never trust the operator's id/path strings verbatim — intersect
  them with the in-memory inventory (or DB row set) before kicking
  the work off. The browser is an unprivileged client even when
  the operator is the only user.
- Keep a no-form fallback so CLI / curl callers can act on "all
  actionable rows" without crafting form fields.

## Tree-shaped data in a table: indent, don't decorate

If the data has hierarchy (call graph, scene → tracks, folder
tree) and you're rendering it in a table, use plain depth-based
`padding-left` on the first column. **Don't** draw the tree with
Unicode box characters (`│ ├── └──`):

- Table cells have padding + line-height between rows. The
  `│` from row N and row N+1 are visually adjacent but never
  flow into one continuous line — the operator sees broken
  rungs and assumes the rendering is buggy.
- Monospace span + non-monospace surrounding text breaks
  alignment further the moment a row wraps or grows.
- The indent alone is enough to communicate depth; the operator
  reads top-to-bottom anyway.

If you genuinely need the connectors, render the whole tree in a
`<pre>` block (single monospace box, line-height: 1), not in a
table. Otherwise: just indent.

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
      elements (spinner, progress bar) — drive rotation from a
      global rAF tick anchored to wall-clock time.
- [ ] Every time / byte / count value goes through a shared
      formatter (`humantime`, `humansize`, tabular figures).
- [ ] No hardcoded hex outside the token map, unless the colour
      carries a fixed semantic meaning (state pill, traffic light,
      category).
- [ ] No two timelines stacked on top of each other. Media is
      scrubbed via the analytics timeline, not the browser's.
- [ ] Plain `<form>` POSTs return a `303` redirect (or full page),
      not `HX-Redirect: …` with an empty body.
- [ ] Detail page shows latest pipeline state + failures at the
      top, not buried on a scan/queue page.
- [ ] Selectable list with mixed states uses a real checkbox for
      actionable rows + a static glyph for done rows; header
      checkbox supports `indeterminate`; default-checked for trim,
      not opt-in.
- [ ] Operator-submitted keys/paths/ids are intersected with the
      live truth before the handler acts.
- [ ] Tree-shaped data in a table uses depth-based `padding-left`,
      not Unicode box-drawing connectors.

## When in doubt

Two questions, in order:

1. **What is the operator trying to decide on this row?**
2. **What's in their way?**

Everything that doesn't help answer (1) is a candidate for
deletion. Anything that gets in the way of (2) — extra clicks,
scrolling, ambiguous labels, slow polls — is a regression no
matter how it looks.
