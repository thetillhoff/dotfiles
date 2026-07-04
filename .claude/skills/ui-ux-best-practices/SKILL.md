---
name: ui-ux-best-practices
description: >
  Battle-tested UI and UX principles for any user-facing interface — web,
  mobile, consumer product, or internal operator tool. Covers layout, hierarchy,
  typography, color, interaction feedback, forms, navigation, accessibility, and
  operator-specific patterns (density, tables, keyboard-first,
  decisions-per-minute). Grounded in Nielsen's heuristics, Tog's principles,
  Gestalt laws. Use when building a screen, page, form, or component; auditing a
  UI ("why does this feel off", low conversion, accessibility review); stripping
  AI slop; or building an operator tool, admin UI, control panel, queue,
  dashboard, or back-office tool. Triggers on "UX", "usability", "user flow",
  "make it intuitive", "is this good UI", "admin UI", "control panel", "back
  office". Principles layer — invoke alongside frontend-design (aesthetic
  direction) and interface-kit (implementation craft). NOT for: copy/content
  (copywriting), charts/data viz (dataviz), design-system specs (design-system),
  or HTMX patterns (htmx).
---

# UI & UX Best Practices

Design that gets out of the way. If the user does not have to fight it, it
becomes invisible. Every choice below serves that: reduce effort, remove
surprise, make the next action obvious.

**How to use:** treat the sections as a checklist when building, and as a
critique lens when reviewing. For the named theory (Nielsen's 10 heuristics,
Tog's principles, Gestalt laws, color schemes, layout patterns) consult
`references/frameworks.md` — cite by name when justifying a decision.

## 1. Start with the user, not the screen

Before laying anything out: who is the user, what is their goal, what is the
flow that gets them there? Sketch the **user journey** first; the UI is just the
path. Design each screen around the one thing the user came to do.

- **Progressive disclosure** — ask one thing at a time, not everything at once.
- **Above vs below the fold** — be deliberate about what is seen without
  scrolling. Put the primary action and value there.
- **Familiar patterns** — do it the way most products do it. Novelty in
  mechanics is a tax; spend it only where it is the point.

## 2. Layout & hierarchy

Guide the eye. A viewer should know where to look first, second, third without
being told. Three levers, applied together:

- **Size & weight** — important things are bigger and bolder.
- **Contrast** — important things stand apart from their surroundings.
- **Spacing** — important things get room; grouping conveys relationship.

Rules of thumb:

- **Whitespace is breathing room**, not wasted space. Do not crowd. Under-design
  before you over-design — shadows, borders, and effects pile up into noise.
- **Strict grid** — align everything to a spacing system (e.g. an 8pt grid).
  Alignment reads as competence; drift reads as sloppy.
- **Proximity** — things that belong together stay together (Gestalt).
- **Cards** to show where a discrete item begins and ends. **Split screens** for
  two items of equal hierarchy. **Grids/tables** for uniform collections.
- **F-pattern** (text-heavy pages) and **Z-pattern** (sparse landing pages)
  match how eyes actually scan — place key elements on those paths.
- **Perspective / flow** — position elements where the flow expects them
  (submit at the end of a form, not the top).

## 3. Typography

- **Max two font families.** More fragments the page.
- **Type conveys tone** — heavy/bold vs light/sleek, classic vs modern. Pick
  intentionally.
- **Readability first** — generous size, high contrast, comfortable line length.
- Define a **type scale** (sizes, weights, line-heights) and reuse it; do not
  set sizes ad hoc.

## 4. Color

- Build a **palette from a scheme**: monochromatic, analogous, complementary,
  split-complementary, triadic, or tetradic. Do not pick colors at random.
- **Color as a tool** — success/warning/error carry meaning; never rely on color
  alone (colorblind users need a second cue: icon, label, shape).
- **Contrast** must pass in **both light and dark mode**. Detect the user's
  system preference and support both — and always verify both; they break
  independently.

## 5. Interaction & feedback

Every tap, click, or drag gets a response — a subtle one is usually enough. The
absence of feedback reads as "broken".

- **Immediate acknowledgment** (<~50 ms for the visible reaction). Loading
  spinners for waits, hover/pressed states, success toasts.
- **Clickable things look clickable** — interactive elements must stand out
  (color, emphasis). Links are underlined and blue-ish by convention; do not
  strip the affordance.
- **Icons clarify, not complicate** — keep a text label beside an icon in most
  cases; an icon alone is a guessing game.
- **Smart defaults** — pre-fill and pre-select the likely choice. Do not
  autoplay media. Defaults must be replaceable.
- **Keyboard shortcuts** for frequent/expert actions; keep them discoverable but
  out of a beginner's way.

## 6. Forms & input

Forms are where users quit. Reduce effort and never punish.

- **Validate per-input, inline, as they go** — tell the user about a problem on
  the field itself, not only after they hit submit.
- **Never clear a field on error.** Losing typed data is the fastest way to lose
  a user.
- **Accessible label on every input** (not placeholder-as-label). Placeholder
  text is a hint, not a substitute for a label.
- **Recognition over recall** — offer suggestions, autocomplete, and pickers
  instead of a blank box the user must fill from memory.
- **Clear call-to-action**: verb + noun ("Submit form", "Create account"), not a
  bare "Submit" or "OK".

## 7. Navigation

- **Visible and consistent** — users should always know where they are and how to
  get back. Highlight the current location; use breadcrumbs where depth warrants.
- **Logo in the nav links to home** (expected everywhere; its absence surprises).
- **User control & freedom** — always provide undo, cancel, and a clear exit.

## 8. Accessibility (non-negotiable)

- **Semantic HTML** — use the right element for the job; it gives you keyboard
  and screen-reader behavior for free.
- **ARIA labels** where semantics are not enough; **alt text** on every
  meaningful image (empty `alt=""` on purely decorative ones).
- **Scalable, high-contrast fonts**; respect user zoom and reduced-motion.
- **Full keyboard navigation** — everything reachable and operable without a
  mouse. Never use `outline: none` without providing a visible replacement.

## 9. Design system

Once past a couple of screens, stop deciding the same thing twice. Define once,
reuse everywhere — typography scale, color usage, button styles & states,
spacing, border-radius, animation speed, and shared components (tables, cards,
grids). This is what makes a product feel like one product.

## 10. Least design necessary

Default to the least design code that does the job. Every element, style, and
effect must earn its place by serving the user's goal; if removing it changes
nothing for the user, remove it.

Be especially skeptical of **AI design slop** — the generated-looking defaults
that pile on because they are easy to add, not because anyone needs them:
gratuitous gradients and glassmorphism, drop shadows on everything, decorative
hero blobs and floating icons, purple-to-pink gradients, emoji-as-feature-icons,
three-column "feature" grids that say nothing, animation for its own sake,
rounded-everything, and copy like "Elevate your workflow". These read as
templated and untrustworthy, and they add cognitive load.

Before shipping any element, ask:

- Does the user's task need this, or does it just fill space?
- Would a plainer version work as well or better?
- Is this here because it is genuinely useful, or because it looked "designed"?

A native control beats a custom one. A plain button beats a styled one when the
plain one communicates the same thing. Restraint is the tell of a real designer;
excess is the tell of a generator. When unsure, cut it.

---

## 11. Operator UIs

An operator tool is not a marketing site. The metric is **decisions per minute**
— how fast the operator gets through the work the system has surfaced. This
inverts several defaults from the sections above.

### Density over whitespace

For consumer UIs, whitespace is breathing room. For operator UIs, whitespace is
wasted scrolling. Pack the page. Every extra scroll costs a decision.

### Information density

- **Tables, not cards**, for repeating rows of structured data. Cards are for
  rows that have visual content the eye actually scans (thumbnails, photos,
  mini-charts).
- Multiple pieces per row: short label + value + state pill + tiny action group.
- Group by what the operator triages by, not by data-model layout.

### Real-time feedback

A button that fires a long job replaces its label with a spinner + a
present-progressive verb. No trailing ellipsis — the spinner is the "still
working" signal; the word names the work.

- Simple: `Scan` → `⟳ Scanning`
- Multi-step: `⟳ Retrieving data` → `⟳ Analysing` → `⟳ Writing output`

Polling widgets (1–2 s) for anything long-running: job progress, service
status, host load. They tell the operator nothing is stuck.

Every polling fragment on the same page uses the **same interval** — mixing 2 s
and 5 s ticks reads as broken sync. Both fast or both slow, never mixed. Ship a
`↻ refresh now` button beside a cadence dropdown (`off / 1 s / 2 s / 5 s / 10 s
/ 30 s`), persisted per-page in localStorage: novices get a sensible default,
power users slow it down to inspect stable state or turn it off.

**One polling `hx-trigger` per swap region.** Nested polls (2 s outer + 1 s
inner) tear each other down every swap; if the inner ever returns `HX-Redirect`
on a transient not-running state, the whole page navigates and buttons vanish
(symptom: a button that flickers every other second). Fold the inner poll into
the outer template, and give every stable element a fixed `id` so idiomorph
preserves it across swaps.

Toasts name the actual entities ("Merged track #5 into #3"), not just "Success".
The operator should be able to undo manually from that information alone.

#### Failure banner sits with the progress widget

For any entity that runs through a backend pipeline, the detail page shows the
*latest pipeline state* at the top — a polled fragment that renders one of three
things: a "running" header with the active stage + elapsed time, a red banner
with the error + a re-run button on failure, or nothing when idle and healthy.
Don't bury failures on a "scan" page; the operator opened the detail page
because something looked wrong.

#### Show the active stage, not a fallback apology

When a multi-stage pipeline can't report fine-grained progress for the current
stage, display just the stage name + elapsed time. Don't write "worker hasn't
reported per-frame progress yet" — that reads as malfunction. Absence of a
progress bar with a named stage already means "this stage is opaque".

#### Multi-phase runners: phase chip beside the counter, never instead of

A runner with several internal phases (scene-detect → sample → per-frame ML →
post-processing) resets its frame counter on each phase. If the phase chip only
renders as a fallback when no counter exists, the operator watches the bar go
95% → 0% mid-file and reads "runner restarted" as a bug. Any `stage` / `phase` /
`step` key renders as a chip whenever present, *alongside* the frame/byte
counter — the chip carries the "same file, new sub-stage" signal.

#### Time values name their axis and render human-readable

Progress rows often show two seconds-valued times side by side — wall-clock
("how long running") and media-timeline position ("where in the source file").
A raw `1175.3s … t_sec=979.8` gives no way to tell them apart. Prefix a noun
that names the axis (`elapsed 19m 35s`, `remaining …`), render `hh:mm:ss` via
the shared `humantime` formatter, and pair a media-timeline value with its total
(`video 16m 19s / 24m 03s`) to match the scrubber shape. Never leak an internal
key like `t_sec` into the UI — the template maps it to the labelled version.

#### Inventory shows only what needs a click

Filter the pending-work table to **actionable** states — `new` + `failed`.
Hide `in_progress` (already visible in the service-status rows), `completed`
(lives on the entity detail page), and `outdated` / `incomplete` (surface via a
state-pill counter: `outdated 3 · incomplete 1`). Keep the full state-counts
pill row (`new 42 · failed 3 · in_progress 7 · completed 118`) as the true
denominator; the table below is the filtered click-list. **Failed rows are
treated as new for retry** — the primary action clears whatever partial state
the last attempt left (Redis keys, sidecar files, sqlite rows) and re-fires
from scratch. No separate "retry" verb.

#### Pipeline snapshot: prefer the stage with real progress

If multiple services hold the same source in flight (a dispatcher + a worker),
the dispatcher's entry often has no `detail` payload. Return the job whose
`detail` carries the metric you want to show (`frames_done`, `bytes_uploaded`,
…), not the first match. "Dispatcher is busy" isn't what the operator wants
to read.

#### Spinner that survives polled swaps

CSS `@keyframes` restarts to 0° every time HTMX replaces an ancestor element —
even with `hx-preserve` on a fresh DOM node. The result is a stuttering spinner
that resets every poll. Drive rotation from a single global
`requestAnimationFrame` tick instead:

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

Anchor rotation to wall-clock time so freshly inserted spinners pick up the
current phase on the next frame — no visible reset. CSS keeps the spinner's
appearance (size, border, color); JS owns its motion.

### Design system specifics

Lock these in early; retroactive consistency is expensive:

- **Spacing scale**: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px. Every padding,
  margin, and gap is a multiple of 4.
- **Type scale**: 12 / 14 / 16 / 18 / 24 / 32. Never reach for an intermediate
  size.
- **Two font families**: proportional for prose and UI labels; monospace for
  paths, hashes, IDs, and numeric data that changes (tabular figures).
- **Concentric border-radius** on nested rounded elements: outer = inner +
  padding. Skip this and inner cards look bloated.
- **Two state palettes**: one for domain states (analysed / new / failed /
  running), one for traffic-light pills (red / amber / green). Both used
  consistently site-wide.
- **No information conveyed by color alone**: pair every pill with a label or
  icon — numbers are the truth, color is the at-a-glance aid.
- **Tooltips on every badge, pill, and computed metric**: any abbreviated label,
  color-coded chip, percentage, score, or short status word gets a `title="…"`
  (or equivalent) that spells out what it measures and how to read it. If the
  operator has to ask "what does this number mean?", the UI failed.
- **One formatter per unit, used everywhere**: time → `humantime`
  (`3h 02m 04s` / `5m 12s` / `42s`), bytes → `humansize` (`B / KB / MB / GB`,
  1 decimal), counts always tabular-numbered, paths shown via `<code>` with a
  monospace face. Raw seconds, raw bytes, or ad-hoc `"%.1f KB"` anywhere in
  templates is a bug — the operator builds muscle memory for the shape and a
  stray format breaks the eye.
- **Auto dark mode from day one**: define colour tokens at `:root` for light,
  override the same tokens inside
  `@media (prefers-color-scheme: dark) { :root { … } }`. Set `color-scheme:
  light` / `dark` on `:root` so native controls follow the theme. Retrofitting
  dark mode later costs far more than building both at once.

### Action vocabulary

Words in the UI are design material. Keep them consistent:

- Action buttons use the verb of what they do. Button says "Merge"; resulting
  toast says "Merged X into Y."
- Destructive actions name the target. Not "Delete" — "Delete person Y
  (3 samples)".
- Entity names (track, scene, person, source) stay the same across pages. No
  synonym pile.
- Labels describe the concept, not the value. "Status: Disabled" reads cleanly;
  "Enabled: Disabled" is a contradiction.
- Empty states are short, useful sentences ("No proposals at the current
  threshold. Lower the slider or scan more files."), not decoration.

### Keyboard-first

Every routine action (merge, move, next, previous, reject, jump) has a
single-key shortcut. The mouse is for spot-fixes. Tab order matches reading
order. Focus ring visible at all times.

**Exception:** non-reversible actions (delete, clear, drop) never get a bare
single-key shortcut. They go through a confirm prompt that names the target, or
sit behind a modifier chord. Reversible actions live on the hot path; destructive
ones live one extra step away.

### Motion budget

High-frequency actions get no animation; rare actions can afford it.

| Element | Duration |
| --- | --- |
| Hover, focus ring, button-press | ≤100 ms or none |
| Dropdown, popover, in-place swap | 150–250 ms |
| Polling refreshes | replace the fragment in place — no fade-in, no slide |
| Onboarding / celebration | only if it helps the operator notice something they would otherwise miss |

`transition: all` is banned. Always specify what transitions.

Respect `prefers-reduced-motion`: reduce durations to ~0 while keeping
opacity/color feedback (which is feedback, not decoration).

### What to avoid (operator-UI AI-slop tells)

- No purple-to-blue gradients on white. Pick a palette grounded in what the data
  actually is.
- No "Welcome back!" greetings. The operator is at work.
- No engagement-bait copy ("What do you think?"). State facts.
- No false ranges in labels ("0 to ∞ tracks"). Concrete numbers or none.
- No identical card clusters and three-button sections repeated across every page
  — that is layout autopilot, not design.

### Progressive enhancement

The server renders a fully working page first. Dynamic updates (live polling,
in-place swaps) layer on top. If JavaScript fails, the operator can still see and
navigate everything; they just lose the live feedback.

### When in doubt

Two questions, in order:

1. **What is the operator trying to decide on this row?**
2. **What is in their way?**

Everything that does not help answer (1) is a candidate for deletion. Anything
that gets in the way of (2) — extra clicks, scrolling, ambiguous labels, slow
polls — is a regression no matter how it looks.

### Media with analytics — unify the scrubber

Pages that pair a media element (video, audio) with layered analytics (scene
cuts, tracks, error markers) almost always render two timelines: the native
browser scrubber inside `<video>` + a custom timeline below. They never line up.

**Hide the native control and make the custom timeline the seekbar.** One
physical timeline, one set of geometry:

- Drop the `controls` attribute. Render a custom row: play/pause button,
  monospace time display (current / total).
- A vertical playhead line absolutely positioned over all lanes,
  `left: (currentTime / duration * 100%)`, updated on `timeupdate`. Shares the
  same `.lane-area` width the bars use — alignment is by construction.
- Bars seek to their start time on click. Empty space in any lane seeks to the
  click's relative X.
- `Space` toggles play/pause when focus isn't in a text field.
- Drop lane-label columns; put a caption above each lane so bars span 100%
  width (the only way to match the player's spatial timeline).
- Overlay a live state badge on the player ("Scene #N · 0s → 18m"), updated on
  `timeupdate`.
- The playhead line must be **grab-able** — mousedown captures, mousemove
  updates `currentTime`, mouseup releases. Add a wider invisible hit zone via
  `::after` (~14 px total). CSS transition off while `.scrubbing` class is set
  so the line tracks the cursor without lag.

### Tunable algorithms in the UI

If the analytics pipeline has tunable parameters (detector thresholds, model
temperatures, clustering radii), put them in a collapsible panel on the entity's
detail page — not in env vars or admin scripts.

- One row per algorithm: enable checkbox + `<input type="range">` sliders with a
  live `<output>` driven by `oninput`.
- "Apply" runs the cheapest recomputation — never a full re-analysis if only
  one stage's parameters changed.
- Saved state at three levels: per-entity override → global default → hardcoded
  fallback. Same form renders on `/<entity>/<id>` and `/settings`.
- Spell out the trade-off each detector makes next to its row, not in external
  docs.
- When Apply triggers derived row rebuilds, warn about collateral damage in the
  button hint ("operator scene merges are lost on re-detect because scene ids
  change").

#### Every knob: drag + type + reset

Each slider gets three affordances side by side:

- `<input type="range">` carries the form `name` — drag for coarse motion.
- `<input type="number">` (unnamed, JS-mirrored) for typed exact values.
  Bidirectional via `input` events; only the range submits.
- `↺` reset button restores `input.defaultValue` (value at page load, not zero,
  not the global default).

Slider ranges must cover the metric's natural domain. A slider capped at 100
for a metric that ranges 0–255 is a bug.

#### Cache the expensive metric; recompute composition live

Separate **feature extraction** (expensive, one decode pass) from **scoring
composition** (cheap, depends on operator knobs):

- First Apply runs the heavy pipeline once, writes per-frame metric arrays to a
  sidecar file.
- Subsequent slider drags re-run only the cheap composition against the cached
  metrics. Pure JS for the live preview, server-side for the canonical commit.
- Share the formula between client and server. Forking the math is how you
  discover a bug 30 commits later when the operator says "the preview lied".

#### Live preview must rAF-throttle

Slider `input` events fire many times per second during drag. If the redraw is
non-trivial, wrap it in a `requestAnimationFrame` guard — at most one DOM update
per frame. The math runs the same number of times; only the DOM update is
throttled.

### Backend state surfaces on the status page

When the backend supports states beyond up/down (draining, restarting, paused,
version-mismatched, queue-saturated), the status page shows them explicitly. A
draining service that still answers `/status` with `draining: true` reads as a
yellow "draining" pill, not as "OK" (lying) or "unreachable" (also lying).
Operators triage off this page; ambiguity costs minutes.

### Bulk actions: primary + destructive in one row

When a list page supports both a non-destructive bulk verb (re-run, requeue)
and a destructive one (delete), they sit in the same toolbar with the same
checkbox set:

- Primary action on the left, destructive on the right.
- One counter per button, updated together by a single change listener. Both
  buttons disabled until at least one row is ticked.
- `hx-post` on each button so they hit different endpoints with the same form
  data. The `<form>` itself has no action.

### Selectable list with mixed row states

For a list where some rows are already done and the operator picks from the
remaining ones:

- **Done rows** render a non-interactive glyph (`✓` in the state-ok color). Do
  NOT render a disabled checkbox — it looks like "you forgot to fix this".
- **Actionable rows** render a real `<input type="checkbox">` **default-checked**.
  The operator trims, not opts in row by row.
- **Header-row checkbox** toggles every actionable row at once. Support all
  three states: all-checked, none-checked, `indeterminate` for partial.
- **Live counter** in the action button: "Analyse 7 of 23 new files". Button
  disabled when count is 0.
- **`form="…"` attribute** lets checkbox inputs live inside the data table
  while posting through a `<form>` rendered elsewhere — no need to wrap the
  table.
- **Backend validates submitted keys** against the live truth before acting.
  Never trust the operator's id/path strings verbatim.

### Tree-shaped data in a table: indent, don't decorate

If the data has hierarchy and you're rendering it in a table, use depth-based
`padding-left` on the first column. **Don't** draw the tree with Unicode box
characters (`│ ├── └──`):

- Table cells have padding + line-height between rows. The `│` from row N and
  row N+1 are never continuous — the operator sees broken rungs and assumes the
  rendering is buggy.
- The indent alone communicates depth; the operator reads top-to-bottom anyway.

If you genuinely need connectors, render the whole tree in a `<pre>` block
(monospace, `line-height: 1`), not in a table.

---

## Self-review checklist

Run this before shipping any screen. The **General** items apply to every UI;
the **Operator UI** items apply when the audience is a single-operator workflow.

### General

- Primary action is visible without scrolling (above the fold or immediately
  reachable).
- Every interactive element has a clear affordance (hover state, cursor change,
  or visual distinction).
- Every link is underlined or otherwise distinguishable from body text.
- Tab order matches the visual reading order.
- Focus ring is visible on every focusable element — never `outline: none`
  without a visible replacement.
- Full keyboard navigation: every action reachable without a mouse.
- Color contrast ≥ 4.5:1 for normal text, ≥ 3:1 for large text and UI
  components. Verified in both light and dark mode independently.
- No information conveyed by color alone — paired with a label, icon, or shape.
- Every meaningful image has descriptive `alt` text; decorative images use
  `alt=""`.
- Every form field has a visible, persistent label (not just a placeholder).
- Inline per-field validation — error appears on the field, not only on submit.
- Errors do not clear the field value.
- All CTA buttons use verb + noun ("Create account", not "Submit").
- Destructive actions require an explicit confirmation that names the target.
- Loading, empty, and error states are all handled and styled consistently with
  success states — not bolted on after.
- Long async operations show a progress or spinner indicator; no button locks
  silently.
- `prefers-reduced-motion` reduces animation durations to ~0 while preserving
  color/opacity feedback.
- `transition: all` is absent — all transitions specify what properties change.
- The page renders usably with JavaScript disabled (or degraded gracefully).
- Semantic HTML throughout — `<button>` for actions, `<a>` for navigation, lists
  for lists, headings in order.
- ARIA labels present where HTML semantics are insufficient.
- Design-system tokens used for all spacing, type sizes, and colors — no ad-hoc
  values.
- No AI-slop tells: no gratuitous gradients, decorative blobs, purple-to-pink
  color schemes, emoji icons, shadow-on-everything, or placeholder-sounding copy.

### Operator UI (additional)

- All routine actions have a single-key keyboard shortcut.
- No non-reversible action sits on a bare single-key shortcut — confirm prompt or
  modifier chord required, and the prompt names the actual target.
- Every row's state is legible without hovering or clicking into it.
- Counts in headings match the row count in the table beneath them.
- Long jobs spawn a progress widget with a present-progressive verb; the trigger
  button does not lock silently.
- Toast messages name the actual entities mutated ("Merged track #5 into #3"),
  not just "Success".
- Entity names are consistent across pages — no synonym pile.
- Labels describe the concept, not the value ("Status: Disabled", not
  "Enabled: Disabled").
- Empty states include a useful, actionable sentence — not just an illustration.
- Durations and timestamps are rendered human-readable (`3m 4s`, `2 days ago`),
  not raw seconds or ISO strings.
- If polling is used, refreshes replace content in place with no fade-in or
  slide. Stable elements inside the polled fragment (spinners, progress bars) are
  not restarted on each swap — drive rotation from a global rAF tick, not CSS
  keyframes.
- Every polling fragment on the page uses the same interval — no mix of 2 s +
  5 s ticks. Operator can change cadence (dropdown + `↻ refresh now`, persisted
  per-page), and at most one polling trigger fires per swap region.
- Every time value carries an axis-naming label (`elapsed …`, `remaining …`,
  `video … / …`) — never a bare number; media-timeline position pairs with its
  total.
- Multi-phase runners emit a `stage` / `phase` chip that renders alongside
  frame/byte counters, not only as a fallback when they're absent.
- Pending-work inventory shows only actionable states (`new` + `failed`);
  non-actionable states surface via the state-pill counter. Failed rows
  self-recover — the primary action clears partial state and retries, no
  separate "retry" verb.
- No "Welcome back!" greeting or engagement-bait copy anywhere.
- Spacing, type sizes, and border-radius all come from the locked design-system
  scales — no intermediate values.
- Every time / byte / count value goes through a shared formatter (`humantime`,
  `humansize`, tabular figures) — no ad-hoc format strings in templates.
- No hardcoded hex colors outside the token map, unless the color carries a
  fixed semantic meaning (state pill, traffic light, category).
- Detail page shows the latest pipeline state + any failures at the top, not
  buried on a separate scan/queue page.
- Plain `<form method="post">` handlers return a `303` redirect (or full page),
  never just `HX-Redirect: …` with an empty body — bare HX-Redirect is invisible
  to a non-HTMX request.
- Media is scrubbed via the analytics/custom timeline, not the native browser
  scrubber — no two overlapping timelines.
- Selectable list with mixed states: actionable rows use a real default-checked
  checkbox; done rows use a static glyph (not a disabled checkbox). Header
  checkbox supports `indeterminate`.
- Operator-submitted ids/paths are intersected with the live truth before the
  handler acts — never trust form values verbatim.
- Tree-shaped data in a table uses depth-based `padding-left`, not Unicode
  box-drawing connectors.
