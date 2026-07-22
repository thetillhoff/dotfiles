# Performance & Core Web Vitals

Perceived speed is a UX property, not just an engineering one - a slow interface
reads as broken (§5) and users leave. Optimize against the metrics users feel,
not synthetic scores. Verify the premise before optimizing: measure the real
bottleneck (a trace, a Lighthouse/WebPageTest run) before assuming one.

## The three Core Web Vitals

| Metric | Measures | Good | What moves it |
| --- | --- | --- | --- |
| **LCP** (Largest Contentful Paint) | Load - when the biggest element paints | ≤ 2.5 s | Slow server/TTFB, render-blocking CSS/JS, unoptimized hero image, lazy-loaded LCP |
| **INP** (Interaction to Next Paint) | Responsiveness - worst input→paint latency | ≤ 200 ms | Long JS tasks blocking the main thread, heavy event handlers, large re-renders |
| **CLS** (Cumulative Layout Shift) | Visual stability - unexpected movement | ≤ 0.1 | Images/ads/embeds with no reserved space, late-loading fonts, injected banners |

INP replaced FID in 2024 - it's the full interaction latency, so it's the metric
that catches janky handlers, not just the first tap.

## LCP - make the important thing paint fast

- **Never lazy-load the LCP image** (see web-implementation.md). Mark it eager +
  `fetchpriority="high"`; `preload` it if the URL is known at request time.
- **Eliminate render-blocking resources.** Inline critical CSS; defer the rest.
  `<script>` at end of body or `defer`/`type=module`; `async` only for
  independent scripts.
- **TTFB first** - a slow server or redirect chain caps LCP no matter what the
  front end does. Cache, CDN, avoid redirect hops.
- Serve modern image formats at the right size (AVIF/WebP, `srcset`).

## CLS - reserve space for everything that arrives late

- **Every image/video/iframe/ad slot has reserved dimensions** - `width`+`height`
  attributes or `aspect-ratio`. The single biggest CLS source.
- **Fonts**: use `font-display: swap` (or `optional`) to avoid invisible text,
  and set `size-adjust` / `ascent-override` on the `@font-face` so the fallback
  metrics match the web font - otherwise the swap itself shifts layout. `preload`
  the critical font.
- Don't inject content above existing content (cookie bars, "you have 1 new…"
  banners) without reserving its space; insert at the top only in already-empty
  reserved regions.
- Animate only `transform`/`opacity` (compositor-only) - never animate layout
  properties (`top`, `height`, `margin`) which reflow and can shift neighbors.

## INP - keep the main thread free

- **Break up long tasks** (> 50 ms). Chunk work, `requestIdleCallback`, or move
  heavy compute to a Web Worker so input can be handled between chunks.
- **Debounce/throttle** high-frequency handlers (input, scroll, resize, pointer);
  guard non-trivial DOM writes behind `requestAnimationFrame` (one paint/frame).
- Give instant visual acknowledgment on click (§5) even if the result is async -
  optimistic UI beats a frozen frame.
- Ship less JS: hydration and large re-renders are the usual INP culprits.
  Server-rendered HTML + light enhancement (htmx) sidesteps most of this.

## Perceived performance

Actual and perceived speed diverge - manage the perception too:

- **Skeletons over spinners** for content-shaped loads; shape them like the real
  layout (see design-patterns.md). Spinner for short/unknown waits.
- **Optimistic UI** - reflect the user's action immediately, reconcile when the
  server responds; roll back visibly on failure.
- **Instant feedback < 100 ms**; show a determinate progress bar from 0% for
  known-duration work (see the operator progress section in SKILL.md §12).
- Prioritise above-the-fold: load and render what's visible first, defer the rest
  (lazy images below the fold, code-split routes).

## Budgets

Set a budget and hold the line - performance regresses silently. A rough
starting point for a content/app page: JS ≤ ~150-200 KB gzipped, total ≤ ~1 MB,
LCP image appropriately sized (not a 4000px hero scaled to 800px). Enforce in CI
(Lighthouse CI, bundle-size checks) - a budget nobody measures is a wish.
