# WCAG / Accessibility Reference

The standards behind the Accessibility section of SKILL.md. Target **WCAG 2.2
level AA** - the real-world and legal floor (US Section 508, EU EN 301 549, UK
Equality Act, ADA case law all map to AA). Use this when auditing, or when you
need the exact criterion/number behind a rule.

## POUR - the four principles

- **Perceivable** - text alternatives, captions, sufficient contrast; never
  convey info by a sensory characteristic (color/shape/position) alone.
- **Operable** - everything works by any input (keyboard, no timing traps, no
  seizure triggers), navigable and findable.
- **Understandable** - readable, predictable behavior, input help and error
  recovery.
- **Robust** - valid markup with correct name/role/value so assistive tech works
  now and later.

## Conformance levels

- **A** - minimum; alone rarely a real target.
- **AA** - the target for essentially all products. Aim here.
- **AAA** - enhancement; cherry-pick where feasible, not expected site-wide.

## Version deltas (each version is a superset; 2.2 is current stable)

**2.1 added** (mobile, low-vision, cognitive):

- **Reflow** - usable at **320px** CSS width with no two-dimensional scrolling.
- **Text spacing** - no loss when the user overrides line-height/letter/word/
  paragraph spacing (avoid fixed-px text container heights).
- **Content on hover/focus** - tooltips/popovers must be dismissable, hoverable,
  and persistent.
- **Orientation** - don't lock to portrait or landscape.
- **Identify input purpose** - `autocomplete` tokens on personal-data fields.
- **Pointer gestures / cancellation** - no path- or multipoint-only gestures;
  fire on the up-event and allow cancel.
- **Motion actuation** - a non-motion alternative to any device-motion control.

**2.2 added:**

- **Target size (minimum) - interactive targets ≥ 24×24 CSS px** (or adequate
  spacing). (44×44 is the stricter AAA / Apple-HIG figure; 24 is the AA floor.)
- **Focus not obscured** - sticky headers/footers must not fully hide the focused
  element.
- **Dragging movements** - every drag action needs a single-pointer (tap/click)
  alternative.
- **Accessible authentication** - no cognitive-function test (memorizing,
  transcribing, puzzles) to log in; allow paste, password managers, emailed
  codes.
- **Consistent help** - a help/contact mechanism in the same relative order
  across pages.
- **Redundant entry** - don't force re-entering info already given in the same
  process.
- (2.2 *removed* 4.1.1 Parsing - obsolete for modern parsers.)

## WCAG 3.0 - do not target yet

Editor's Draft, years from recommendation, and it does **not** deprecate 2.x -
keep building to 2.2 AA. It restructures to guidelines → outcomes → assertions
and moves from binary pass/fail toward an outcome/scoring model with graded
levels. Details are unstable; 2.2 AA is expected to satisfy most of its minimum.

## Top criteria engineers miss - concrete build rules

- **Text contrast** - normal text ≥ **4.5:1**; large (≥24px, or ≥18.7px bold) ≥
  **3:1**.
- **Non-text contrast ≥ 3:1** - UI component boundaries, icons, focus rings, form
  borders, chart data against adjacent color.
- **Focus appearance** - the visible ring needs enough area and contrast, and
  must not be covered by sticky UI.
- **Target size** - ≥ 24×24px hit area (spacing exception applies).
- **Reflow / text spacing** - no clipping or horizontal scroll at 320px; survive
  user spacing overrides.
- **Resize text** - usable at **200% zoom** without loss; size in `rem`/`em`, not
  fixed px.
- **Use of color** - never color-only for errors/required/status/links; add
  icon, text, or underline. Keep body links visually distinct (underline, not
  color alone).
- **No keyboard trap** - focus can always leave every widget and modal.
- **Bypass blocks** - a skip-to-content link or landmark regions.
- **Page titled / headings & labels / focus order** - unique `<title>`, one
  logical `<h1>`, no heading-level skips, DOM order = visual order.
- **Labels or instructions** - every input has a persistent visible label plus
  format hints (not placeholder-as-label).
- **Error identification + suggestion** - name the field in the error, in text,
  and suggest the fix; associate via `aria-describedby`.
- **Status messages** - `role="status"` / `aria-live="polite"` for
  non-focus-stealing updates, `alert` for urgent.
- **Timing** - adjustable or no time limits; pause/stop/hide for auto-updating or
  moving content lasting > 5 s.
- **Three flashes** - nothing flashes more than 3×/second.
- **Language of page** - set `<html lang>` (and `lang` on inline foreign
  passages).

## Design-phase rules (decide before build)

- Left-align body text (avoid justified); avoid long ALL-CAPS runs (hurts
  dyslexic readers).
- Distinguish buttons from links by role and styling - affordance must match
  actual behavior.
- Write descriptive link/button text at design time ("Download report", not
  "click here").
- Design the visible focus indicator as a deliberate style token, not a dev
  afterthought.
- Design the heading outline, the 200%-zoom state, and the 320px reflow up front
  - reflow is a layout decision, not a retrofit.
- Test with real assistive tech (VoiceOver/NVDA) and an audit before launch;
  WCAG 2.2 AA self-assessment is not enough for high-stakes services.

## Test procedures (run these, don't eyeball)

- **Zoom to 200% and 400%** - content reflows to a single column with no
  horizontal scroll and nothing clipped or overlapping.
- **Text-spacing override** - apply letter-spacing 0.12em, word-spacing 0.16em,
  line-height 1.5, paragraph-spacing 2em; everything stays readable and
  unclipped. (Fixed-px text-container heights fail this.)
- **Forced colors / Windows High Contrast** (`forced-colors: active`) - UI stays
  usable when the OS overrides colors; don't kill borders/outlines that carry
  meaning, and don't set backgrounds that hide `forced-color-adjust` text.
- **Focus indicator quality** - the ring meets 3:1 contrast against adjacent
  colors and encloses at least a 2px perimeter; "technically visible" isn't
  enough.
- **Keyboard-only pass** and an **automated scan** (axe-core / Lighthouse /
  pa11y) in CI.
