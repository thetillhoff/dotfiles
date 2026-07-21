# Web Implementation Recipes

Concrete, copy-pasteable best-practices for common web parts. Lookup reference -
reach for the relevant section when building that specific thing.

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
