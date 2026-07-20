---
name: ui-ux-best-practices
description: >
  Battle-tested UI and UX principles for any user-facing interface - web,
  mobile, consumer product, or internal operator tool. Covers layout, hierarchy,
  typography, color, interaction feedback, forms, navigation, accessibility, and
  operator-specific patterns (density, tables, keyboard-first,
  decisions-per-minute). Grounded in Nielsen's heuristics, Tog's principles,
  Gestalt laws. Use when building a screen, page, form, or component; auditing a
  UI ("why does this feel off", low conversion, accessibility review); stripping
  AI slop; or building an operator tool, admin UI, control panel, queue,
  dashboard, or back-office tool. Triggers on "UX", "usability", "user flow",
  "make it intuitive", "is this good UI", "admin UI", "control panel", "back
  office". Principles layer - invoke alongside frontend-design (aesthetic
  direction) and interface-kit (implementation craft). NOT for: copy/content
  (copywriting), charts/data viz (dataviz), design-system specs (design-system),
  or HTMX patterns (htmx).
---

# UI & UX Best Practices

Design that gets out of the way. If the user does not have to fight it, it
becomes invisible. Every choice below serves that: reduce effort, remove
surprise, make the next action obvious.

**How to use:** treat the sections as a checklist when building, and as a
critique lens when reviewing. Before shipping, re-scan each section's **bold
lead-ins** - they are the pass/fail gate. For the named theory (Nielsen's 10
heuristics, Tog's principles, Gestalt laws, color schemes, layout patterns)
consult `references/frameworks.md` - cite by name when justifying a decision.

## 1. Start with the user, not the screen

Before laying anything out: who is the user, what is their goal, what is the
flow that gets them there? Sketch the **user journey** first; the UI is just the
path. Design each screen around the one thing the user came to do.

- **Progressive disclosure** - ask one thing at a time, not everything at once.
- **Above vs below the fold** - be deliberate about what is seen without
  scrolling. Put the primary action and value there.
- **Familiar patterns** - do it the way most products do it. Novelty in
  mechanics is a tax; spend it only where it is the point.

## 2. Layout & hierarchy

Guide the eye. A viewer should know where to look first, second, third without
being told. Three levers, applied together:

- **Size & weight** - important things are bigger and bolder.
- **Contrast** - important things stand apart from their surroundings.
- **Spacing** - important things get room; grouping conveys relationship.

Rules of thumb:

- **Whitespace is breathing room**, not wasted space. Do not crowd. Under-design
  before you over-design - shadows, borders, and effects pile up into noise.
- **Strict grid** - align everything to a spacing system (e.g. an 8pt grid).
  Alignment reads as competence; drift reads as sloppy.
- **Proximity** - things that belong together stay together (Gestalt).
- **Cards** to show where a discrete item begins and ends. **Split screens** for
  two items of equal hierarchy. **Grids/tables** for uniform collections.
- **F-pattern** (text-heavy pages) and **Z-pattern** (sparse landing pages)
  match how eyes actually scan - place key elements on those paths.
- **Perspective / flow** - position elements where the flow expects them
  (submit at the end of a form, not the top).

## 3. Typography

- **Max two font families.** More fragments the page.
- **Type conveys tone** - heavy/bold vs light/sleek, classic vs modern. Pick
  intentionally.
- **Readability first** - generous size, high contrast, comfortable line length.
- Define a **type scale** (sizes, weights, line-heights) and reuse it; do not
  set sizes ad hoc.

## 4. Color

- Build a **palette from a scheme**: monochromatic, analogous, complementary,
  split-complementary, triadic, or tetradic. Do not pick colors at random.
- **Color as a tool** - success/warning/error carry meaning; never rely on color
  alone (colorblind users need a second cue: icon, label, shape).
- **Match the hue to the item's meaning.** Amber/yellow reads as *caution*, red
  as *error*, green as *good/active/best*. Don't paint a neutral, purely
  informational chip amber just because it needs to stand out - it reads as a
  warning that isn't one. Use a neutral (gray) as the default "nothing's wrong,
  just info" and reserve the traffic-light hues for real state; the
  best/closest/selected item is green, not amber.
- **Contrast** must pass in **both light and dark mode**. Detect the user's
  system preference and support both - and always verify both; they break
  independently.

## 5. Interaction & feedback

Every tap, click, or drag gets a response - a subtle one is usually enough. The
absence of feedback reads as "broken".

- **Immediate acknowledgment** (<~50 ms for the visible reaction). Loading
  spinners for waits, hover/pressed states, success toasts.
- **Clickable things look clickable** - interactive elements must stand out
  (color, emphasis). Links are underlined and blue-ish by convention; do not
  strip the affordance.
- **Icons clarify, not complicate** - keep a text label beside an icon in most
  cases; an icon alone is a guessing game.
- **Every value is labelled** - a number with a unit (duration, timestamp, size,
  count) never stands alone; show what it measures. In a table that's the
  column/row header; inline or in a pill it's a leading noun (`elapsed 19m 35s`,
  `12.4 MB uploaded`). Critical when several same-unit values sit together - a
  bare `1175.3s … 979.8` is unreadable. Render human-readable; never surface a
  raw internal key.
- **Smart defaults** - pre-fill and pre-select the likely choice. Do not
  autoplay media. Defaults must be replaceable.
- **One authoritative control per value** - two widgets representing the same
  underlying value (a timeline, a map extent, a scroll position, paired range
  sliders) drift out of sync. Pick one as the source of truth and derive or
  replace the other.
- **An action shouldn't flip a mode the user set** - navigating, seeking, or
  saving must not silently reset a deliberate choice (theme, playback state,
  sort order, filter, zoom). Preserve it; change it only via an explicit control
  for that mode.
- **A helper action gives feedback where the operator clicked.** Confirm on the
  control itself (button label → `Adopted ✓` for ~1 s); never scroll the
  viewport to a distant element or move focus off the button. Yanking the scroll
  position or focus mid-task is as disorienting as clearing a typed field - the
  operator loses their place. (A "jump to the thing this affects" is a *separate*,
  explicit navigation action, not a side effect of a helper button.)
- **An action that produces no visible change reads as broken.** If an
  `Apply` / `Adopt` / `Set` can't produce the effect it promises (a no-op edge,
  nothing matched, a value that mathematically changes nothing), give explicit
  feedback or disable the control - silence is indistinguishable from a bug, and
  the operator clicks it again wondering what happened.
- **Informational-with-actions → an info pill, not a hidden button.** When an
  element is primarily information but carries actions, render the info as text
  plus explicit labelled buttons inside it. Don't make the whole element one
  ambiguous click-target - "the pill does something when clicked, but what, and
  where?" is a guessing game.
- **Keyboard shortcuts** for frequent/expert actions; keep them discoverable but
  out of a beginner's way.

## 6. Forms & input

Forms are where users quit. Reduce effort and never punish.

- **Validate per-input, inline, as they go** - tell the user about a problem on
  the field itself, not only after they hit submit.
- **Never clear a field on error.** Losing typed data is the fastest way to lose
  a user.
- **Accessible label on every input** (not placeholder-as-label). Placeholder
  text is a hint, not a substitute for a label.
- **Recognition over recall** - offer suggestions, autocomplete, and pickers
  instead of a blank box the user must fill from memory.
- **Clear call-to-action**: verb + noun ("Submit form", "Create account"), not a
  bare "Submit" or "OK".

## 7. Navigation

- **Visible and consistent** - users should always know where they are and how to
  get back. Highlight the current location; use breadcrumbs where depth warrants.
- **Logo in the nav links to home** (expected everywhere; its absence surprises).
- **User control & freedom** - always provide undo, cancel, and a clear exit.

## 8. Accessibility (non-negotiable)

- **Semantic HTML** - use the right element for the job; it gives you keyboard
  and screen-reader behavior for free.
- **ARIA labels** where semantics are not enough; **alt text** on every
  meaningful image (empty `alt=""` on purely decorative ones).
- **Scalable, high-contrast fonts**; respect user zoom and reduced-motion.
- **Full keyboard navigation** - everything reachable and operable without a
  mouse. Never use `outline: none` without providing a visible replacement.
- **Keep informational text selectable** - ids, paths, hashes, error messages,
  and timestamps must stay copyable. If you disable selection for an interaction
  (e.g. shift-click row range-select), scope `user-select: none` to the
  interactive control only, never a whole container that also holds copyable
  text.

## 9. Design system

Once past a couple of screens, stop deciding the same thing twice. Define once,
reuse everywhere - typography scale, color usage, button styles & states,
spacing, border-radius, animation speed, and shared components (tables, cards,
grids). This is what makes a product feel like one product.

## 10. Least design necessary

Default to the least design code that does the job. Every element, style, and
effect must earn its place by serving the user's goal; if removing it changes
nothing for the user, remove it.

Be especially skeptical of **AI design slop** - the generated-looking defaults
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

An operator tool is not a marketing site. The metric is **decisions per
minute** - how fast the operator gets through the work the system has
surfaced. This inverts several defaults from the sections above.

### Density over whitespace

For consumer UIs, whitespace is breathing room. For operator UIs, whitespace is
wasted scrolling. Pack the page. Every extra scroll costs a decision.

### Information density

- **Tables, not cards**, for repeating rows of structured data. Cards are for
  rows that have visual content the eye actually scans (thumbnails, photos,
  mini-charts).
- Multiple pieces per row: short label + value + state pill + tiny action group.
- Group by what the operator triages by, not by data-model layout.

### Progress & feedback for long actions

**Acknowledge the click instantly on the control.** A button that fires a long
job replaces its label with a working state so the click registers - at minimum a
spinner + present-progressive verb (`Scan` → `⟳ Scanning`), no ellipsis; the
spinner is the "working" signal, the verb names the work.

**Then show the finest signal the job actually produces** - never leave it at
just "in progress":

- Reports a percentage → a progress bar, started at `0%` from the first frame.
  Don't show a spinner that later morphs into a bar - that morph is a flicker.
- Reports stages but no fine number → the stage name + elapsed (`Analysing ·
  0:12`). Don't apologise ("worker hasn't reported yet") - that reads as
  malfunction; a named stage with no bar already means "this stage is opaque".
- Multi-phase runner whose counter resets each phase → render the phase/stage
  chip *alongside* the counter, always, not only as a fallback. Otherwise the bar
  drops 95% → 0% mid-item and reads as a crash.
- Fully opaque → the control's spinner + verb is all there is, and that's fine.
- Several services report the same work → surface the one carrying real detail
  (the worker, not a dispatcher that only knows "busy").

**Don't flicker.** Each visible state persists long enough to read
(~300-500 ms), never flashing one you replace within a blink; if the real number
is already there, show it directly. If it never arrives within a timeout, fall to
an explicit stalled/failed state - don't spin forever.

**Surface failure with the progress, at the top of the detail page.** One polled
fragment renders the latest state: a running header (active stage + elapsed), a
red banner + re-run button on failure, or nothing when idle and healthy. Don't
bury failures on a separate scan/queue page - the user opened the detail page
because something looked wrong.

### Polling

- Poll long-running state (job progress, service/host status) every 1-2 s so the
  user sees nothing is stuck.
- Every polling fragment on a page uses the **same interval** - mixed 2 s / 5 s
  ticks read as broken sync. Offer a `↻ refresh now` button + cadence dropdown
  (`off / 1 / 2 / 5 / 10 / 30 s`), persisted per-page.
- **One poll per region, never nest.** A poll inside an already-polling fragment
  gets rebuilt every swap and can navigate the page away on a transient state
  (symptom: a button flickering every other second). See the **htmx** skill.
- A spinner or progress bar inside a polled fragment must not restart its
  animation each swap (reads as "stuck") - see the htmx "animated-element gotcha"
  (move it outside the swap target, `hx-preserve`, or a global rAF tick).

### Inventory shows only what needs a click

Filter the pending-work table to **actionable** states - `new` + `failed`.
Hide `in_progress` (already visible in the service-status rows), `completed`
(lives on the entity detail page), and `outdated` / `incomplete` (surface via a
state-pill counter: `outdated 3 · incomplete 1`). Keep the full state-counts
pill row (`new 42 · failed 3 · in_progress 7 · completed 118`) as the true
denominator; the table below is the filtered click-list. **Failed rows are
treated as new for retry** - the primary action clears whatever partial state
the last attempt left (cache entries, temp files, db rows) and re-fires
from scratch. No separate "retry" verb.

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
  icon - numbers are the truth, color is the at-a-glance aid.
- **Tooltips on every badge, pill, and computed metric**: any abbreviated label,
  color-coded chip, percentage, score, or short status word gets a `title="…"`
  (or equivalent) that spells out what it measures and how to read it. If the
  operator has to ask "what does this number mean?", the UI failed.
- **Numbers human-readable, via one shared formatter per unit** - so the user
  builds muscle memory for the shape and no stray format breaks the eye.
- **Auto dark mode from day one**: define colour tokens at `:root` for light,
  override the same tokens inside
  `@media (prefers-color-scheme: dark) { :root { … } }`. Set `color-scheme:
  light` / `dark` on `:root` so native controls follow the theme. Retrofitting
  dark mode later costs far more than building both at once.

### Action vocabulary

Words in the UI are design material. Keep them consistent:

- Action buttons use the verb of what they do. Button says "Merge"; resulting
  toast says "Merged X into Y."
- Destructive actions name the target. Not "Delete" - "Delete person Y
  (3 samples)".
- Entity names (track, scene, person, source) stay the same across pages. No
  synonym pile.
- Labels describe the concept, not the value. "Status: Disabled" reads cleanly;
  "Enabled: Disabled" is a contradiction.
- **A verb-label names a mechanism - re-audit it when the mechanism changes.**
  "Apply" fit while a button re-ran detection; once it only persisted the config
  - the already-previewed result, "Save" is truer. When you change what an
  action *does*, grep its label, hint/tooltip, and nearby comments for the old
  verb and update them together - a stale label mis-teaches the operator.
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
| Polling refreshes | replace the fragment in place - no fade-in, no slide |
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
  - that is layout autopilot, not design.

### Progressive enhancement

The server renders a fully working page first. Dynamic updates (live polling,
in-place swaps) layer on top. If JavaScript fails, the operator can still see and
navigate everything; they just lose the live feedback.

### When in doubt

Two questions, in order:

1. **What is the operator trying to decide on this row?**
2. **What is in their way?**

Everything that does not help answer (1) is a candidate for deletion. Anything
that gets in the way of (2) - extra clicks, scrolling, ambiguous labels, slow
polls - is a regression no matter how it looks.

### Media with analytics: one timeline, not two

A concrete instance of *one authoritative control per value* (§5). When a media
element (video, audio) is paired with a custom analytics timeline (scene cuts,
tracks, markers), the native `<video>` scrubber and the custom timeline never
line up. **Hide the native control and make the custom timeline the only
seekbar** - one physical timeline, one geometry, alignment by construction.

- Custom controls: play/pause button, current/total time, and a playhead
  positioned over the analytics lanes by `currentTime / duration`, sharing the
  lanes' width so it aligns exactly.
- Click anywhere (a marker or empty track) seeks to that point; the playhead is
  draggable, with a generous hit zone.
- `Space` toggles play/pause (only when focus isn't in a text field).
- **Seek and jump preserve the current play state** - if paused, the target
  stays paused for inspection; if playing, playback continues. Never auto-start
  or auto-stop on navigation; flipping the state fights the user's intent.

### Tunable parameters belong in the UI, not config files

If an algorithm has parameters worth tuning (thresholds, weights, radii), expose
them as knobs in a collapsible panel where the work is - not in env vars or admin
scripts. Whoever tunes sees the effect immediately.

- One row per parameter: enable checkbox + slider with a live value readout.
- Apply runs the *cheapest* recomputation - never a full re-analysis when only
  one stage's inputs changed (see below).
- Defaults cascade: per-item override → global default → hardcoded fallback. The
  same form renders on the item page and the global settings page.
- Spell out each parameter's trade-off next to its row, not in external docs.
- When Apply rebuilds derived data, warn about collateral damage in the button
  hint ("manual merges are lost on re-detect - ids change").

**Each knob: drag + type + reset.** A range slider for coarse motion, a number
input for exact values (synced both ways), and a reset that restores the value at
page load (not zero, not the global default). The slider range must cover the
parameter's natural domain - one capped at 100 for a 0-255 value is a bug.

#### Cache the expensive part; recompute the cheap part live

When a tunable result splits into an **expensive stage** (run once) and a
**cheap stage** that depends on the user's knobs, cache the expensive output and
recompute only the cheap stage on each knob change:

- First run does the heavy work once and caches its output; later knob changes
  re-run only the cheap composition against that cache.
- **Share the formula between the live preview and the canonical commit.** Fork
  the math and you find out 30 commits later when the user says "the preview
  lied".
- The commit path reuses the same cheap recompute - re-run the expensive stage
  only when *its* own inputs changed or the cache is gone.
- **Tell that they've forked:** preview is instant but commit is slow on the
  same change - the commit is redoing expensive work whose inputs didn't move.
  The cheap path usually already exists (wired into the preview, not the commit).

**Throttle the live preview.** Slider drag fires many events per second; if the
redraw is non-trivial, guard it with `requestAnimationFrame` so at most one DOM
update happens per frame. The math still runs each time; only the paint is
throttled.

### Backend state surfaces on the status page

When the backend supports states beyond up/down (draining, restarting, paused,
version-mismatched, queue-saturated), the status page shows them explicitly. A
draining service that still answers `/status` with `draining: true` reads as a
yellow "draining" pill, not as "OK" (lying) or "unreachable" (also lying).
Operators triage off this page; ambiguity costs minutes.

### Active state outranks a stale terminal state

In a status classifier, a currently-active state (running / in-progress) takes
priority over a prior attempt's terminal state (failed / done). A re-triggered
item that's being reprocessed reads *in-progress*, not the *failed* it was
before. Base "active" on a **live signal** - work actually in flight now (a
pending/running job), not a lingering marker from the last run. Keep the
error/audit log **independent** of the current-state indicator: the log
persists until manually cleared; the state pill reflects now. If the re-run
fails again, the terminal state resurfaces on its own.

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
  NOT render a disabled checkbox - it looks like "you forgot to fix this".
- **Actionable rows** render a real `<input type="checkbox">` **default-checked**.
  The operator trims, not opts in row by row.
- **Header-row checkbox** toggles every actionable row at once. Support all
  three states: all-checked, none-checked, `indeterminate` for partial.
- **Live counter** in the action button: "Analyse 7 of 23 new files". Button
  disabled when count is 0.
- **`form="…"` attribute** lets checkbox inputs live inside the data table
  while posting through a `<form>` rendered elsewhere - no need to wrap the
  table.
- **Backend validates submitted keys** against the live truth before acting.
  Never trust the operator's id/path strings verbatim.

### Tree-shaped data in a table: indent, don't decorate

If the data has hierarchy and you're rendering it in a table, use depth-based
`padding-left` on the first column. **Don't** draw the tree with Unicode box
characters (`│ ├── └──`):

- Table cells have padding + line-height between rows. The `│` from row N and
  row N+1 are never continuous - the operator sees broken rungs and assumes the
  rendering is buggy.
- The indent alone communicates depth; the operator reads top-to-bottom anyway.

If you genuinely need connectors, render the whole tree in a `<pre>` block
(monospace, `line-height: 1`), not in a table.
