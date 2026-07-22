# Web Implementation Recipes

Concrete, copy-pasteable best-practices for common web parts. Lookup reference -
reach for the relevant section when building that specific thing.

- [Responsive images](#responsive-images)
- [Modern CSS techniques](#modern-css-techniques)
- [Layout recipes](#layout-recipes)
- [Visual polish](#visual-polish)

## Responsive images

### Which technique

- **Same image, different sizes/densities** → plain `<img srcset sizes>`. The
  browser picks the best candidate. This is the default.
- **Different crop/aspect per breakpoint (art direction), OR next-gen format
  fallback** → `<picture>` with `<source>`. `<picture>` is the only way to do
  format negotiation and media-based source switching.

### `srcset` + `sizes` (resolution switching)

- Width descriptors (`w`) + `sizes` for responsive layouts; density (`x`)
  descriptors only for fixed-size images (logos, avatars).
- `sizes` tells the browser the rendered width *before layout* so it picks a
  candidate early - keep it in sync with your CSS. `sizes="auto"` (2024+, pair
  with `loading="lazy"`) uses the real layout width; newer support, so still
  provide a fallback list.

```html
<img
  src="photo-800.jpg"
  srcset="photo-400.jpg 400w, photo-800.jpg 800w, photo-1600.jpg 1600w"
  sizes="(max-width: 600px) 100vw, 50vw"
  width="1600" height="900"
  alt="…" loading="lazy" decoding="async">
```

### `<picture>` (art direction + format fallback)

- Order sources best-to-worst; the browser takes the first `<source>` it
  supports. Always terminate with a plain `<img>` - it is the fallback and
  carries `alt`, `width`, `height`, `loading`.
- Format order: AVIF → WebP → JPEG/PNG. The `type` attribute gates by codec.
- Each `<source>` may itself carry `srcset` + `sizes`; art-direction variants
  add `media="(max-width:600px)"`.

```html
<picture>
  <source type="image/avif" srcset="hero.avif">
  <source type="image/webp" srcset="hero.webp">
  <img src="hero.jpg" width="1200" height="630" alt="…"
       fetchpriority="high" decoding="async">
</picture>
```

### Performance attributes

- `loading="lazy"` - below-the-fold images only. **Never on the LCP /
  above-the-fold hero** - it delays the largest paint. Leave those eager and add
  `fetchpriority="high"`.
- `decoding="async"` - safe default; keeps decode off the main thread.
- `fetchpriority` - `high` on the LCP image, `low` for offscreen/decorative.
- Don't lazy-load *and* mark high-priority on the same element - contradictory.

### Prevent layout shift (CLS)

- Always set intrinsic `width` + `height` attributes (browser derives
  `aspect-ratio` and reserves space) OR set `aspect-ratio` in CSS.
  Non-negotiable for a good CLS score.
- With responsive CSS, keep `height: auto` so the ratio holds as width scales.

### Fit & positioning

- `object-fit: cover|contain` fills the box without distortion;
  `object-position: 50% 20%` sets the focal point (e.g. keep faces in frame on a
  crop).

### Format tradeoffs (2025, all evergreen-supported)

- **AVIF** - best compression, HDR/wide-gamut + alpha; slower encode, occasional
  artifacting on flat gradients at low quality.
- **WebP** - smaller than JPEG/PNG, faster encode; good middle tier and
  near-universal fallback.
- **JPEG/PNG** - final fallback only (PNG for lossless/transparency).
- **SVG** - icons and line art.

## Modern CSS techniques

Baseline (2025) unless flagged. Prefer these over the old hacks they replace.

- `clamp(min, preferred, max)` - fluid type/spacing without media queries:
  `font-size: clamp(1rem, 0.5rem + 2vw, 2rem)`.
- `min()` / `max()` - constraint sizing: `width: min(100%, 60ch)` for a
  self-limiting container.
- **Container queries** (`container-type: inline-size` + `@container`) - style by
  *parent* width, not viewport. The real fix for genuinely reusable components.
- **`:has()`** - relational/parent selector: `.card:has(img)`, sibling and
  form-state styling without JS. The biggest recent win.
- **Logical properties** - `margin-inline`, `padding-block`, `inset-block`,
  `border-inline-start`. Direction-agnostic (RTL/vertical); prefer over physical
  `left/right/top/bottom`.
- `aspect-ratio: 16/9` - reserve box proportions without the padding hack.
- `gap` works in flexbox too (not just grid) - replaces margin spacing hacks.
- Native CSS nesting (`&`) - no preprocessor needed for evergreen targets.
- `accent-color` - one-line brand theming of checkboxes/radios/range/progress.
- `color-scheme: light dark` - opt into native dark UA styling (form controls,
  scrollbars); pairs with `light-dark()` (newer ~2024 - verify support).
- `scroll-snap-type` / `scroll-snap-align` - carousels/galleries snapping with
  no JS.
- `inset: 0` - shorthand for the four offset properties.
- `@layer` cascade layers - explicit cascade ordering to tame specificity wars
  and third-party CSS. High value on large codebases.
- Custom properties with fallbacks `var(--c, crimson)` - runtime theming;
  animatable via `@property` (newer).
- `@supports (…)` - gate cutting-edge properties for progressive enhancement.
- `clip-path: polygon(…)` - non-rectangular shapes and reveals.

**Newer / support-caveated** - use as progressive enhancement, degrade
gracefully: `text-wrap: balance` (even ragged headings) and `text-wrap: pretty`
(fixes body-text orphans); `subgrid`; standard `scrollbar-width` /
`scrollbar-color` (keep `::-webkit-scrollbar` fallback if needed); `sizes="auto"`;
`light-dark()`; `@property`-animated custom properties.

## Layout recipes

### The two headline tricks

- **Auto-responsive grid, zero media queries:**
  `grid-template-columns: repeat(auto-fit, minmax(min(<target>, 100%), 1fr))`.
  `auto-fit` collapses empty tracks (items stretch to fill the row); `auto-fill`
  keeps empty tracks (items hold their target width). The `min(<target>, 100%)`
  guard prevents overflow when the screen is narrower than `<target>`. This is
  the default for any card/tile grid of unknown count.
- **Let a flex/grid child actually scroll:** an overflow child inside a grid or
  flex parent won't shrink below its content unless you add `min-height: 0`
  (vertical) or `min-width: 0` (horizontal). The classic "why won't this pane
  scroll" gotcha.

### Named page layouts

- **App shell (sticky header/footer, scrolling body):**
  `body { min-height: 100dvh; display: grid; grid-template-rows: auto 1fr auto }`.
  Use `dvh`, not `vh`, so the mobile URL bar doesn't clip it. The `1fr` middle row
  gives a sticky footer with no JS.
- **Holy grail** (header / left-nav · main · right-aside / footer): one body-level
  grid with `grid-template-areas`; redefine the areas to a single column in one
  mobile media query.
- **Sidebar + content, no media query:** flex with `flex: 1 1 <rail-basis>` on the
  rail and `flex: 999 1 <content-min>` on the main, plus `flex-wrap` - it
  auto-stacks when the main can't keep its minimum width.
- **Centered measure** (readable prose): `max-width: 60-75ch` with
  `margin-inline: auto`, plus `padding-inline` so it never kisses the edges.
- **Full-bleed within a centered column:** a grid with named lines lets children
  break out of the measure to full width -
  `[full-start] minmax(1rem,1fr) [content-start] min(65ch,100%) [content-end] minmax(1rem,1fr) [full-end]`;
  children default to the `content` column and opt into `full`.
- **Dashboard grid:** named `grid-template-areas` + `grid-auto-flow: dense`; tiles
  span with `grid-column: span N`; give each tile a container query so a widget
  restyles by its own width, not the viewport.
- **Split-pane** (list/detail, editor/preview): 2-col grid, each pane
  `overflow: auto; min-height: 0`. Resizable via `resize: horizontal` or a drag
  handle.

### Composition primitives (Every Layout)

Small single-purpose layout objects that compose by nesting - each owns one axis
of concern, and each takes its spacing step from the one 8pt scale so rhythm stays
consistent:

- **Stack** - vertical rhythm between siblings: `flex-direction: column; gap: <step>`.
- **Cluster** - wrapping inline group (tag lists, button rows):
  `flex-wrap: wrap; gap; align-items: center`.
- **Cover** - vertical centering with pinned top/bottom (hero, empty state):
  `min-height: 100dvh; flex-direction: column; justify-content: center`.
- **Reel** - horizontal-scroll strip (carousels, chip rows):
  `display: flex; overflow-x: auto; gap` + `scroll-snap-type: x`.
- **Imposter** - centered overlay: `position: absolute; inset: 0; margin: auto`.

### Responsive strategy

- **Content-driven breakpoints** - add a breakpoint where *the content* breaks
  (line length gets ugly, items cramp), not at device widths (768/1024). Fewer,
  ad-hoc breakpoints beat a device ladder.
- **Shell → media query; reusable component → container query.** Page-global
  structure keys off the viewport; a component that appears in a sidebar, main,
  and full-width must adapt to *its own* width.
- Reach for intrinsic sizing (`min-content` / `max-content` / `fit-content()`)
  and `clamp()` before adding a breakpoint at all.

### Navigation layouts

- **Top nav** - few top-level items, marketing/content sites (horizontal Z-scan).
- **Sidebar nav** - many destinations, app/dashboard, deep IA; collapse to an
  icon rail to reclaim width.
- **Bottom-tab bar** - mobile app-like, 3-5 primary destinations in thumb reach;
  pad with `env(safe-area-inset-bottom)` for notched phones.
- **Responsive nav** - collapse the top nav to a menu button below a breakpoint;
  a `<details>`/`<summary>` disclosure gives a no-JS baseline, JS only enhances.
- **Mega-menu** only when a category has many sub-destinations worth previewing.

### A robust component inventory

When sizing a design system, the components that carry the real accessibility
work are the **overlays** (dialog, alert-dialog, drawer, popover, tooltip,
context-menu, menu, toast) and the **rich inputs** (select, combobox,
autocomplete, slider, number field, OTP). Always source these from an accessible
primitive library (focus trap, dismiss behavior, ARIA, floating positioning) -
hand-rolling them is where bugs and a11y failures live. Forms deserve a
`Field`/`Fieldset`/`Form` wrapper layer for labeling + validation, not ad-hoc
`<label>`s.

## Visual polish

The small, compounding craft details that separate "fine" from "considered".

- **Font smoothing** on the root - without it text reads heavy/blurry on macOS at
  small sizes:

  ```css
  html { -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }
  ```

- **Layered shadows over borders** for depth. Stack 2-3 low-opacity shadows at
  increasing blur/spread rather than a `1px solid` line - it mimics how real light
  falls and reads softer:

  ```css
  box-shadow: 0 1px 2px rgba(0,0,0,.04), 0 2px 4px rgba(0,0,0,.04), 0 4px 8px rgba(0,0,0,.04);
  ```

  (On dark surfaces, shadows barely show - convey elevation with a lighter surface
  instead; see color-and-theming.md.)
- **z-index scale tokens**, never ad-hoc magic numbers. Define a named ladder and
  use it everywhere: `--z-base:0; --z-dropdown:10; --z-sticky:20; --z-overlay:40;
  --z-modal:100; --z-popover:500; --z-toast:1000;`.
- **Optical alignment beats geometric.** Asymmetric glyphs (play triangles, icons
  inside buttons, chevrons) look off when centered by math - nudge them until they
  *look* centered.
- **Concentric radius** on nested rounded elements: outer = inner + padding, or the
  inner corner looks bloated (also in SKILL.md §12).
- **Card hover lift** is a subtle `translateY(-2px)`, never more than 4px (gate it
  behind `@media (hover:hover)`; see motion.md).
- **Subtle inset outline on media** for consistent edges against varied
  backgrounds: `img, video { outline: 1px solid rgba(0,0,0,.06); outline-offset: -1px; }`.
- **One type scale, no strays.** Every size comes from the scale
  (12/14/16/18/24/32/48…); a lone 15px or 22px reads as drift.
