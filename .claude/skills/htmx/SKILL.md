---
name: htmx
description: >
  HTMX-specific patterns for server-rendered UIs: form submission strategies
  (HX-Redirect, HX-Refresh, fragment swap), polling fragments, stylesheet
  cache-busting, hx-confirm for destructive actions, hx-preserve for stable
  elements, the animated-element gotcha, and server-rendered multi-step
  wizards. Also covers the common interaction patterns (active search,
  click-to-edit, inline validation, delete-row, lazy load, infinite scroll,
  bulk actions), hx-trigger modifiers, out-of-band / multi-region swaps, and
  which component libraries (daisyUI, Flowbite, Web Awesome) survive fragment
  swaps. Use when building or debugging any HTMX-powered page - polling
  fragments restarting animations, choosing between redirect vs refresh vs
  in-place swap, building a step-by-step form/wizard, an active-search or
  click-to-edit UI, wiring up confirmations, updating several regions from one
  response, or picking an htmx-friendly styling library. Pairs with
  ui-ux-best-practices (operator-UI section) for the surrounding design
  decisions.
---

# HTMX Patterns

HTMX layers live-polling and in-place updates onto a fully server-rendered page.
The server renders a complete, working page first; HTMX is progressive
enhancement - if it fails, the operator can still see and navigate everything.

## Server-rendered first

Default to server-rendered HTML + HTMX partials. No SPA unless the data model
genuinely demands client-side state. Reading View Source should be enough to
understand the page.

## Form submission patterns

Every form action returns exactly one of three responses. Pick one per action
and stick to it - mixing them on the same route causes confusing behavior:

| Response | When to use |
| --- | --- |
| `HX-Redirect: /path` | The action changes the canonical resource the operator is on (e.g. created a new record, navigated away). |
| `HX-Refresh: true` | The action mutates state that affects the whole page but the URL stays the same. |
| Fragment HTML | The action affects only a known region of the page. Return just that fragment; HTMX swaps it in place. |

**`HX-Refresh: true` discards all client-side state** - scroll position, focus,
a playing/seeked `<video>`, drawn `<canvas>`/charts, unsaved form edits. On a
page carrying real client state (a media player, a drawn canvas) it reads as a
jarring full reload (e.g. the video snaps back to t=0). Prefer a fragment swap
that updates only the affected region. Reach for `HX-Refresh` only when the
mutation genuinely invalidates the whole page and there's no client state worth
keeping.

## Scope `hx-trigger` to the element, not the document

`hx-trigger="change from:input"` does **not** mean "when this form's inputs
change" - `from:<selector>` is a **document-wide** selector, so the handler
fires on a `change` from *every* `<input>` on the page. A form wired this way
fires its POST on every unrelated `<input>` anywhere on the page; if that POST
returns `HX-Refresh: true`, an unrelated toggle reloads the whole page and wipes
all client state.

A form's own `change`/`submit` events already **bubble** to the form element, so
listen on the form with no `from:`:

```html
<!-- WRONG: fires on every <input> in the document -->
<form hx-post="/items/{id}/prefs" hx-trigger="change from:input">
<!-- RIGHT: fires only on this form's own inputs (change bubbles up) -->
<form hx-post="/items/{id}/prefs" hx-trigger="change">
```

Use `from:` only when you deliberately want to listen for an event originating
*elsewhere* in the document - and then make the selector as narrow as possible
(`from:#specific-id`), never a bare tag name.

### `hx-trigger` modifiers - the vocabulary

Most htmx UI patterns are just the right trigger modifier. Learn these:

| Modifier | Effect | Powers |
| --- | --- | --- |
| `delay:Nms` | Debounce - resets the timer on each event, fires after quiet | Active search |
| `changed` | Fire only when the value actually differs | Active search (with `delay`) |
| `throttle:Nms` | Rate-limit - fire at most once per N | High-frequency events |
| `once` | Fire a single time | One-shot init |
| `load` | Fire when the element is inserted | Lazy-load a fragment |
| `revealed` / `intersect once` | Fire when scrolled into view (`intersect` inside a scroll container) | Infinite scroll, lazy load |
| `every Ns` | Poll | Progress, live status |
| `key` filters, e.g. `keyup[altKey&&key=='D']` | Fire on a key combo (JS condition in brackets) | Keyboard shortcuts (add `from:body` for global) |

Combine them: `hx-trigger="input changed delay:400ms"` is the canonical
type-to-search debounce.

## Stylesheet cache-busting

Append a `?v=` query parameter to the main stylesheet `<link>` whenever the
file changes. Without it, browsers serve the cached file and operators see stale
styles after a deploy.

```html
<link rel="stylesheet" href="/static/app.css?v=20240601">
```

Automate the version value from a build hash or deploy timestamp so you never
forget to bump it manually.

## Confirmations on destructive actions

Use `hx-confirm` on any action that cannot be undone. The message should name
the actual target - never a generic "Are you sure?".

```html
<button hx-delete="/items/5"
        hx-confirm="Delete item #5 (3 records)?">
  Delete
</button>
```

## Polling fragments

Use `hx-trigger="every 1s"` (or 2 s for less urgent data) on a container to
poll a partial endpoint.

```html
<div hx-get="/jobs/42/status"
     hx-trigger="every 2s"
     hx-swap="outerHTML">
  <!-- current status fragment -->
</div>
```

Keep polling fragments small. Poll only the changing region, not the whole page.

**A poll must not wrap readable content — it eats text selection.** Every swap
destroys and rebuilds the nodes inside the fragment, so any text the user had
selected vanishes a tick later, and a drag in progress re-anchors onto the
rebuilt nodes (it "selects other text"). This is invisible in testing because
nothing looks broken; users report it as "the page keeps clearing my selection".
Same swap also loses focus, scroll inside the region, and open `<details>`.

Two rules keep it clean:

1. **Status polls; content doesn't.** Put the job card / progress line in the
   polled fragment and leave the table, transcript, or log outside it. When the
   content genuinely changes (job finished), have the polled response carry it as
   an out-of-band swap (`hx-swap-oob="true"` on an element with the content's
   `id`) — so the content is swapped at the two moments it changes, not every
   tick.
2. **Stop polling when there is nothing to poll for.** Render the poll trigger
   only while work is in flight; an idle page should make no requests at all. The
   response that observes "finished" simply comes back without the trigger, which
   ends the loop server-side (see *Terminal responses drive lifecycle*).

```html
<!-- WRONG: the results table is inside the polled fragment -->
<div id="status" hx-get="/run/status" hx-trigger="every 2s" hx-swap="outerHTML">
  <p>Running…</p>
  <table>…500 rows the user is reading…</table>
</div>

<!-- RIGHT: poll the card; the table is its own region, swapped OOB when done -->
<div id="status" {% if running %}hx-trigger="every 2s"{% endif %}
     hx-get="/run/status" hx-swap="outerHTML">
  <p>Running…</p>
</div>
<div id="results"><table>…</table></div>
<!-- /run/status returns, only on the tick that sees the run finish:
     <div id="status" …>idle</div>
     <div id="results" hx-swap-oob="true"><table>…fresh…</table></div>  -->
```

If the content must live inside the polled region, morph instead of replace
(idiomorph, stable `id`s) — it reconciles in place and disturbs selection far
less, though a changed text node can still drop it.

**One polling loop per region - never nest polls.** A polling element inside an
already-polling fragment is torn down and rebuilt on every outer swap; the two
race, and if the inner one returns `HX-Redirect` on a transient not-running
state the whole page navigates away and stable elements vanish. Fold the inner
poll's content into the outer template. Give every stable element a fixed `id`
so idiomorph preserves it across swaps.

## The animated-element gotcha

**Problem:** if a spinner or progress bar sits inside a polled fragment, every
poll replaces the DOM node and restarts its CSS animation from frame 0. The
spinner stutters visibly; a progress bar snaps instead of advancing smoothly.

**Three fixes:**

1. **Move the animated element outside the swap target.** The polled fragment
   updates its sibling; the spinner lives in a parent that HTMX never touches.

2. **`hx-preserve` + stable `id`** on the element you want preserved. HTMX
   keeps the existing DOM node when it swaps, so the animation continues
   uninterrupted.

   ```html
   <div hx-get="/jobs/42/status" hx-trigger="every 1s" hx-swap="outerHTML">
     <span id="job-spinner" hx-preserve>⟳</span>
     <span id="job-label">Analysing…</span>
   </div>
   ```

   Only the non-preserved children get replaced. The spinner node is reused.

3. **Global `requestAnimationFrame` tick.** When the animated element must live
   inside the polled region and CSS `@keyframes` still reset even with
   `hx-preserve` (a fresh DOM node restarts at 0°), drive rotation from one
   global rAF loop anchored to wall-clock time. CSS keeps the spinner's
   appearance; JS owns its motion, so a freshly inserted node picks up the
   current phase on the next frame - no visible reset.

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

Prefer option 1 when the layout allows it - simplest, no id management. Use
`hx-preserve` (option 2) when the element must live inside the polled region.
Reach for the rAF tick (option 3) only when `hx-preserve` alone still resets the
animation.

## Morph over replace to avoid flicker

When an event or poll refreshes a sizeable fragment, prefer a **morph** swap
(`hx-swap="morph"` / idiomorph) over `innerHTML =` or `hx-swap="innerHTML"`/
`"outerHTML"`. A full replacement destroys and rebuilds the whole subtree - a
blank frame (visible flicker) plus loss of any client-rendered or interactive
state inside it (drawn charts, scroll position, focus, playing media). Morph
reconciles in place, touching only changed nodes, so an event-driven update
looks as smooth as the live/incremental update you already do elsewhere.

Idiomorph matches nodes by **`id`**. A child with no `id` can be dropped or
rebuilt during a morph. Give any element that must survive a swap - or carry
client state across it - a stable `id`.

## Scroll position inside a polled region

**Problem:** a polled fragment containing a scroll container (a wide table in
`overflow-x: auto`, a log pane, any inner scroller) inserts a *fresh* element on
every swap, and a fresh element starts at offset 0. On a phone, where a wide
table is read by scrolling sideways, a 5 s poll throws the reader back to the
first column - away from the very numbers the poll exists to update. The faster
the poll, the more unusable it gets.

`hx-preserve` is the wrong tool here: it keeps the *old node with its old
content*, so the region stops updating - it fixes the scroll by defeating the
refresh. Reach for it only for elements whose content doesn't change (a spinner).

**Two fixes:**

1. **Morph swap** (idiomorph). Existing nodes are reconciled rather than
   replaced, so the scroller keeps its offset for free. Correct default *when
   you already load the extension* - don't add a dependency for this alone.

2. **Save and restore the offset around the swap.** No dependency, ~15 lines,
   and it generalises to every scroll container on the page. Key the offsets by
   `id`, which means each container needs a stable one.

   ```js
   const offsets = new Map();
   const scrollers = () => document.querySelectorAll("[id].table-scroll");

   document.addEventListener("htmx:beforeSwap", () => {
     for (const el of scrollers()) offsets.set(el.id, el.scrollLeft);
   });
   document.addEventListener("htmx:afterSwap", () => {
     for (const el of scrollers()) {
       const left = offsets.get(el.id);
       if (left) el.scrollLeft = left;
     }
   });
   ```

   `htmx:beforeSwap` still sees the old node in the DOM; `htmx:afterSwap` sees
   the new one. Listening on `document` covers every swap on the page, so no
   fragment has to opt in.

**Better still, question the sideways scroll.** A table that must be scrolled
horizontally to reach its numbers is a desktop table on a phone. If the polled
values are the point, stack each row into a card below the phone breakpoint -
then there is no scroll offset to preserve. Restoring the offset is the fix for
"this table is genuinely wide"; it is not a substitute for a layout that fits.

## Nav + status widget

Pin a canonical nav and a host/process status widget (service states, load) to
every page in a shared layout template. The status widget itself is a small
polled fragment (2–5 s). This gives the operator ambient awareness without
leaving the current view.

## Plain `<form>` POSTs need a real redirect

`HX-Redirect: /elsewhere` is only safe when a handler receives **only HTMX
requests**. A plain `<form method="post">` submission navigates the browser to
the action URL and renders whatever the server returns. An empty body +
`HX-Redirect` is invisible - the operator lands on a blank page.

Return a `303` redirect (or a full page response) from any handler that might be
reached without HTMX.

## Multi-step flows / wizards

A server-rendered wizard (checkout, onboarding) is just sequential fragment
swaps - no client state needed. For the UX rules (step count, states, gating),
see the ui-ux-best-practices "multi-step flows" section; the htmx-specific
mechanics:

- Each step POSTs to the server. On valid input, return the **next step's
  fragment**; on invalid input, return the **same step re-rendered with inline
  errors and the entered values preserved**. Validate server-side - the step
  gate lives on the server, not in the client.
- **Never `HX-Refresh` between steps** - it reloads the page and discards
  everything the user typed. Swap the step fragment instead.
- Render the **progress tracker outside the swapped region** (in the layout) so
  it isn't rebuilt each step, or return it in an out-of-band swap
  (`hx-swap-oob`) when the current-step marker must move. Give it a stable `id`.
- Keep accumulated answers in the server session (or hidden fields echoed each
  step), not client memory - a fragment swap carries no client state forward.

## Common interaction patterns

The canonical htmx recipes (full code at <https://htmx.org/examples/>). Each is a
target + swap + the right trigger:

- **Active search** - `hx-trigger="input changed delay:400ms"`, `hx-target` a
  results container; server returns the rows/list fragment.
- **Click-to-edit** - element with `hx-target="this" hx-swap="outerHTML"`; click
  swaps in an edit form; save `hx-put`s and returns the display markup; cancel
  `hx-get`s it back. The element cycles display ↔ form.
- **Inline validation** - field wrapper `hx-post` on `change`, `hx-target="this"
  hx-swap="outerHTML"`; server returns the wrapper re-classed valid/error with an
  inline message.
- **Delete row (with fade)** - `hx-delete`, `hx-target="closest tr"
  hx-swap="outerHTML swap:1s"`; server returns 200 + **empty body** → row
  removed; `swap:1s` holds `.htmx-swapping` so a CSS fade runs first.
- **Lazy load** - placeholder with `hx-trigger="load"` shows a spinner, then
  swaps in the expensive content.
- **Infinite scroll vs click-to-load** - identical server shape; the sentinel row
  uses `hx-trigger="revealed" hx-swap="afterend"` for infinite, or a button with
  `click` for load-more. Infinite scroll breaks the back button and deep links -
  prefer click-to-load when position/bookmarkability matters, and pair swaps with
  `hx-push-url` when a state should be linkable.
- **Bulk actions** - plain checkboxes as form inputs; POST the form; return only a
  toast, don't re-render the table (inputs keep their own state).
- **Keyboard shortcut** - `hx-trigger="keyup[altKey&&key=='D'] from:body"`.
- **`hx-prompt`** collects a string into the `HX-Prompt` request header (pairs
  with `hx-confirm`); **`hx-encoding="multipart/form-data"`** enables file upload,
  with progress read off the `htmx:xhr:progress` event.
- **Reset a form after a successful POST** -
  `hx-on::after-request="if(event.detail.successful) this.reset()"`; gate on
  `successful` so it only clears on a 2xx.

## Updating multiple regions from one action

Four options, simplest first - reach for the higher one only when the lower can't
express it:

1. **Expand the target** - wrap both regions and return both. Most reliable,
   truest to HATEOAS. Default choice for adjacent regions.
2. **Out-of-band swap** - add `hx-swap-oob="true"` (or `="beforeend:#sel"`) to an
   extra element in the response; htmx routes it to its own id, updating a second
   region without a second request.
3. **Server-triggered event** - respond with `HX-Trigger: newContact`; a separate
   element listens `hx-trigger="newContact from:body" hx-get="/contacts/table"`.
4. Path-deps extension, for broad dependency fan-out.

## Terminal responses drive lifecycle

The **server** decides when a loop ends, via the returned HTML:

- An **empty 200 body** removes the element (delete-row).
- A polled fragment that comes back with `hx-trigger="none"` (or no trigger)
  **stops polling** - swap in a done/terminal fragment to end a progress loop
  rather than signalling completion client-side. Update `role="progressbar"` +
  `aria-valuenow` on each poll for accessibility.

## Styling & component libraries

htmx does interaction; it doesn't style. Pair it with a delivery model that
survives server-rendered fragment swaps (full taxonomy in the
ui-ux-best-practices `frameworks.md`):

- **CSS-class frameworks** (daisyUI - the most explicitly htmx-oriented -
  Flowbite, CoreUI): the server emits classed markup, swaps are trivial, zero
  client state. Best default.
- **Web components** (Web Awesome / ex-Shoelace): behavior travels in the element,
  framework-agnostic. Caveat: a swapped-in custom element must (re)initialise -
  watch attribute-vs-property setting and lifecycle on `htmx:afterSwap`.
- Avoid React-bound libraries (shadcn, Radix, Kuma) - their behavior is React and
  won't run in swapped fragments. For custom widget *behavior* (a combobox, a
  focus trap), port the contracts from `component-behavior.md` instead.

daisyUI's `data-theme` (pure-CSS theming) and Flowbite's `data-*` JS hooks both
coexist cleanly with htmx swaps - a returned fragment carries its own styling/
behavior hooks with no re-wiring.

## What to avoid

- **`hx-boost` on forms that return fragments.** `hx-boost` expects a full page;
  a fragment response renders as a bare partial. Use explicit `hx-get`/`hx-post`
  - `hx-target` instead.
- **Polling the whole page.** Poll only the changing region. Full-page polls
  reset focus and scroll position. Even a scoped poll resets the offset of a
  scroll container inside it - see "Scroll position inside a polled region".
- **Silently swallowing server errors.** Add an `htmx:responseError` listener
  to surface 4xx/5xx responses as a visible error state, not a silent no-op.

  ```js
  document.addEventListener("htmx:responseError", (e) => {
    showErrorToast(`Server error ${e.detail.xhr.status}`);
  });
  ```
