# Color & Theming

How to choose colors with intent and wire them into a maintainable token system.
Builds on the **color-scheme relationships** (monochromatic, analogous,
complementary, triadic…) in `frameworks.md` and the **traffic-light semantics**
in SKILL.md §4 - this file covers meaning, palette selection, tools, and the
token/dark-mode architecture.

## What colors mean (choose with intent, verify per audience)

Associations are real but **culture-dependent** - Western defaults below; verify
for your audience (e.g. red = luck/prosperity in China, white = mourning in parts
of Asia).

- **Red** - urgency, error, passion, appetite (also luck in China). Stop/danger.
- **Orange** - energy, affordability, playfulness; strong CTA accent.
- **Yellow** - optimism, caution, attention; low contrast on white, hard to use
  for text.
- **Green** - success, growth, nature, money, "go".
- **Blue** - trust, calm, stability, competence - why so many banks/enterprise/
  SaaS brands are blue (also why it's a safe, overused default).
- **Purple** - luxury, creativity, wisdom; overused as an AI/tech gradient (avoid
  the purple-to-pink slop).
- **Black** - luxury, sophistication, power. **White** - clean, simple, space.
  **Gray** - neutral, professional; the default "nothing's wrong, just info".
- **Brown/earth** - natural, rugged, warm.

Match hue to the product's positioning and to state semantics (§4) - never paint
a neutral info element with a warning hue.

## Choosing a palette for a product/brand

1. **Start from one brand/primary hue** that fits the positioning (trust →
   blue-ish; energy → warm), then build relationships from it (a scheme from
   `frameworks.md`), not a pile of unrelated colors.
2. **Roles, not a rainbow.** A workable palette is roughly: one **primary**
   (brand + primary actions), one **neutral ramp** (5-10 grays for text,
   borders, surfaces - this is 90% of the UI), optional one **accent/secondary**,
   plus the **semantic set** (success/warning/error/info). Dominant color with
   sharp accents beats evenly-spread color - let neutrals carry most of the page.
3. **Generate tints/shades as a ramp** (e.g. 50→900) so you have consistent steps
   for surfaces, hovers, and borders - don't eyeball one-off lightnesses.
4. **Design in a perceptual space** (OKLCH/HSL) so steps look evenly spaced and
   lightness is predictable; raw hex/RGB math isn't perceptually uniform.
5. **Validate contrast early** (§4, accessibility-wcag.md): text ≥ 4.5:1, UI/
   non-text ≥ 3:1, in **both** light and dark. A pretty palette that fails
   contrast is unusable. Check color-blind safety (don't rely on hue alone).
6. **Restraint** - fewer colors, used consistently, reads as designed; many
   colors read as AI slop (§11).

### Palette generator tools

Fast starting points - generate, then hand-tune for contrast and consistency:

- [Coolors](https://coolors.co/) - fast scheme generator, spacebar to iterate.
- [Adobe Color](https://color.adobe.com/) - color wheel with harmony rules +
  accessibility/contrast tools; [wheel](https://color.adobe.com/create/color-wheel).
- [Paletton](https://paletton.com/) - classic harmony (mono/complementary/
  triad/tetrad) explorer.
- [Colorkit](https://colorkit.co/color-palette-generator/) and
  [ColorUI](https://colorui.io/) - palette + tint/shade ramp generation.
- [Canva](https://www.canva.com/colors/color-palette-generator/) /
  [Figma](https://www.figma.com/color-palette-generator/) - generators, incl.
  extract-from-image.
- [Color Harmony Generator](https://www.colorharmonygenerator.com/) and
  [Unschooled](https://www.unschooled.art/color-scheme-generator/) - harmony-rule
  explorers.

## Design tokens - the theming architecture

Reference colors by **semantic name**, never a raw hex, in components. Use three
tiers so a rebrand or theme swap changes one layer, not every component:

1. **Primitive / global** - the raw ramp: `--blue-500: …`, `--gray-100: …`. No
   meaning, just values.
2. **Semantic / alias** - role-mapped: `--color-primary`, `--color-text`,
   `--color-surface`, `--color-border`, `--color-danger`. Components use *these*.
3. **Component** (optional) - per-component overrides: `--button-bg`,
   `--card-border`, falling back to semantic tokens.

Dark mode = **re-point the semantic tier at different primitives**; components
don't change. Extend to spacing, radius, type, motion, shadow - one source of
truth (see the design-system layers in `frameworks.md`).

## Dark mode done right

- **Not an inversion.** Use dark-but-not-black surfaces (`#111`-`#1e1e1e`, not
  `#000`) and light-but-not-white text (`~#e0e0e0`, not `#fff`); pure black/white
  causes halation and harsh contrast.
- **Desaturate** - saturated colors vibrate on dark; lighten and mute them, and
  raise semantic colors' lightness so they still read.
- **Elevation via lighter surfaces**, not bigger shadows - shadows barely show on
  dark; a raised card is a lighter shade.
- **Test contrast independently** - light and dark pass or fail separately (§4).
- **Mechanism**: define tokens at `:root` for light, override the same tokens in
  `@media (prefers-color-scheme: dark)` (and/or a `.dark` / `[data-theme=dark]`
  class for a manual toggle). Set `color-scheme: light dark` on `:root` so native
  controls (form fields, scrollbars) follow the theme; `light-dark()` (newer)
  picks per-theme values inline. Auto-detect the system preference and offer an
  explicit toggle; persist the choice.
