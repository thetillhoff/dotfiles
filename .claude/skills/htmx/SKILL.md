---
name: htmx
description: >
  HTMX-specific patterns for server-rendered UIs: form submission strategies
  (HX-Redirect, HX-Refresh, fragment swap), polling fragments, stylesheet
  cache-busting, hx-confirm for destructive actions, hx-preserve for stable
  elements, and the animated-element gotcha. Use when building or debugging any
  HTMX-powered page — polling fragments restarting animations, choosing between
  redirect vs refresh vs in-place swap, wiring up confirmations, or caching
  stylesheets. Pairs with ui-ux-best-practices (operator-UI section) for the
  surrounding design decisions.
---

# HTMX Patterns

HTMX layers live-polling and in-place updates onto a fully server-rendered page.
The server renders a complete, working page first; HTMX is progressive
enhancement — if it fails, the operator can still see and navigate everything.

## Server-rendered first

Default to server-rendered HTML + HTMX partials. No SPA unless the data model
genuinely demands client-side state. Reading View Source should be enough to
understand the page.

## Form submission patterns

Every form action returns exactly one of three responses. Pick one per action
and stick to it — mixing them on the same route causes confusing behavior:

| Response | When to use |
| --- | --- |
| `HX-Redirect: /path` | The action changes the canonical resource the operator is on (e.g. created a new record, navigated away). |
| `HX-Refresh: true` | The action mutates state that affects the whole page but the URL stays the same. |
| Fragment HTML | The action affects only a known region of the page. Return just that fragment; HTMX swaps it in place. |

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
the actual target — never a generic "Are you sure?".

```html
<button hx-delete="/tracks/5"
        hx-confirm="Delete track #5 (3 samples)?">
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

**One polling loop per region — never nest polls.** A polling element inside an
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
   current phase on the next frame — no visible reset.

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

Prefer option 1 when the layout allows it — simplest, no id management. Use
`hx-preserve` (option 2) when the element must live inside the polled region.
Reach for the rAF tick (option 3) only when `hx-preserve` alone still resets the
animation.

## Nav + status widget

Pin a canonical nav and a host/process status widget (service states, load) to
every page in a shared layout template. The status widget itself is a small
polled fragment (2–5 s). This gives the operator ambient awareness without
leaving the current view.

## Plain `<form>` POSTs need a real redirect

`HX-Redirect: /elsewhere` is only safe when a handler receives **only HTMX
requests**. A plain `<form method="post">` submission navigates the browser to
the action URL and renders whatever the server returns. An empty body +
`HX-Redirect` is invisible — the operator lands on a blank page.

Return a `303` redirect (or a full page response) from any handler that might be
reached without HTMX.

## What to avoid

- **`hx-boost` on forms that return fragments.** `hx-boost` expects a full page;
  a fragment response renders as a bare partial. Use explicit `hx-get`/`hx-post`
  - `hx-target` instead.
- **Polling the whole page.** Poll only the changing region. Full-page polls
  reset focus and scroll position.
- **Silently swallowing server errors.** Add an `htmx:responseError` listener
  to surface 4xx/5xx responses as a visible error state, not a silent no-op.

  ```js
  document.addEventListener("htmx:responseError", (e) => {
    showErrorToast(`Server error ${e.detail.xhr.status}`);
  });
  ```
