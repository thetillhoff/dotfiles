# Motion & Animation

Framework-agnostic motion guide. Every rule is CSS/web-standard - no library
required. Motion is feedback and continuity, not decoration; over-animation reads
as slop (§11) and slows the user down.

## Animation budget (by frequency)

Match motion cost to how often the user triggers the action.

| Frequency | Example | Rule |
| --- | --- | --- |
| 100+ times/day | command palette, keyboard shortcuts, high-traffic toggles | No animation. Instant. A 300ms open feels sluggish by the 50th use. |
| Occasional | opening a dialog, submitting a form, expanding a panel | Standard motion, 150-300ms. |
| Rare | onboarding, success celebration, first-run empty state | Can delight - longer, more expressive motion is allowed. |

## Easing curve tokens

Built-in `ease`/`ease-in`/`ease-out`/`ease-in-out` are weak and generic. Define
custom curves once as custom properties and reuse everywhere.

```css
:root {
  --ease-out:     cubic-bezier(0.23, 1, 0.32, 1);   /* default UI: enter, appear, respond */
  --ease-in-out:  cubic-bezier(0.77, 0, 0.175, 1);  /* on-screen movement, morphing */
  --ease-drawer:  cubic-bezier(0.32, 0.72, 0, 1);   /* iOS-like sheets, bottom drawers */
  --ease-snappy:  cubic-bezier(0.2, 0, 0, 1);       /* micro-interactions: toggles, checks */
  --ease-decel:   cubic-bezier(0, 0, 0.2, 1);       /* large surface / page / route transitions */
}
```

- `--ease-out` is the default for anything entering or responding.
- Never use `ease-in` alone for UI - it feels sluggish at the start.
- Reserve `linear` for constant-rate motion only: spinners, progress bars,
  hold-to-confirm fills.

## Duration guide (by element)

- Micro-interactions (toggle, checkbox, switch, press): 100-150ms.
- Hover feedback: 150-200ms.
- Standard enter (dialog, panel, popover appear): 150-300ms.
- Exit: 200ms - always faster than the matching enter (see asymmetry below).
- Large/page/route transitions: 300-500ms with `--ease-decel`.

## Enter/exit asymmetry

- Exits are faster than enters. If enter is 400ms, exit is 200-250ms.
- On exit, use a small fixed `translateY` (8-12px), not a full-height slide -
  large exit movement distracts from what remains.
- Combine opacity with a slight `scale(0.96)` on exit; opacity alone feels flat.
- Deliberate actions can have a slow decision but a snappy consequence:
  hold-to-delete may take 2s, but the removal itself is ~200ms. Weight belongs in
  the decision, not the result.

## Scale from 0.95, never from 0

Scale appearing elements from `0.95` (or `0.96`), not from `0`. Scaling from zero
looks like a glitch; a subtle scale reads as physical.

## Stagger / split

- Stagger multi-element entrances by 30-80ms per item. Under 30ms looks
  simultaneous; over 80ms feels sluggish.
- Stagger semantic chunks (cards, rows), not individual lines of text.
- Cap total stagger time: for a long list, stagger the first 5-6 items and let
  the rest appear together.
- Stagger on initial load only - re-renders must not re-stagger.
- Never block interaction during stagger; every item is clickable immediately,
  even before it is visible.

```css
.stagger-item {
  opacity: 0;
  transform: translateY(8px);
  animation: stagger-in 400ms var(--ease-out) forwards;
  animation-delay: calc(var(--index) * 40ms); /* set --index per item */
}
@keyframes stagger-in { to { opacity: 1; transform: translateY(0); } }
```

## Press feedback

Every pressable element compresses slightly on press:
`:active { transform: scale(0.97); }` (0.96-0.97). Tactile, no layout shift.

## Interruptibility - transitions, not keyframes, for interactive state

- For UI that changes rapidly and unpredictably (toasts, dynamically added/removed
  items, drag), use CSS transitions, not keyframe animations. Transitions
  interpolate from the current state; keyframes restart from the beginning and
  cannot adapt mid-flight.
- Keyframes are fine for predetermined, one-shot motion (a spinner, a scripted
  reveal).

## Popover / dropdown transform-origin

- Popovers, dropdowns, and menus animate from the trigger position - set
  `transform-origin` toward the trigger, not `center`.
- Dialogs are the exception: they appear center-screen, so
  `transform-origin: center`.

## Tooltip delay

First tooltip has an open delay (~700ms). While the user moves between adjacent
triggers shortly after, skip the delay on subsequent tooltips so hovering a row of
controls feels instant.

## prefers-reduced-motion - reduce, don't eliminate

Reduced motion means gentler motion, not a dead UI. Keep opacity/color feedback
that aids comprehension; drop movement.

- Keep: opacity fades, color transitions, essential state feedback.
- Remove: parallax, zoom/scale transforms, slide/translate, auto-playing
  carousels.
- Simplify: multi-step animations collapse to a simple fade.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Prefer a per-component reduced variant (keep the opacity fade, drop the translate)
over the blanket reset where you can.

## Hover gate

Gate hover-triggered motion so it never sticks on touch devices (where a tap
counts as a lingering hover).

```css
@media (hover: hover) and (pointer: fine) {
  .card:hover { transform: translateY(-2px); }  /* lift, never more than 4px */
}
```

## `transition: all` is banned

Always name the properties. `transition: all` animates unintended changes (color,
padding, border) and makes jank hard to debug.

```css
/* Bad */  transition: all 200ms ease;
/* Good */ transition: transform 200ms var(--ease-out), opacity 200ms var(--ease-out);
```

## Performance - animate compositor properties only

- Animate only `transform`, `opacity`, and (sparingly) `filter`. Everything else
  (width, height, margin, top/left, background, box-shadow, border) triggers
  layout or paint. See performance.md.
- Keep `blur()` under 20px; `backdrop-filter: blur()` is more expensive still -
  use sparingly, prefer pre-blurred assets.
- `will-change` only for `transform`/`opacity`/`filter`, only to fix an observed
  first-frame stutter, and remove it after. Never `will-change: all`.

## `@starting-style` - pure-CSS enter animations

Define the pre-render state so an element transitions in on insertion, no JS mount
flag needed.

```css
.toast {
  opacity: 1; transform: translateY(0);
  transition: opacity 400ms var(--ease-out), transform 400ms var(--ease-out);
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

Add `transition: display 300ms allow-discrete` to animate elements toggling
`display: none`. For older browsers, fall back to a `data-mounted` attribute added
after one `requestAnimationFrame`.

## clip-path reveals (no layout shift)

`clip-path: inset(top right bottom left [round radius])` reveals/hides content
without reflow. `inset(0 0 0 0)` = fully visible, `inset(50% 50% 50% 50%)` =
hidden. Uses: scroll-in image reveals (animate from `inset(0 0 100% 0)`),
pixel-perfect tab-highlight overlays, hold-to-confirm fills (`linear` over the
hold duration), before/after comparison sliders.

## Springs (when a library is available)

For drag, gestures, and "alive" elements, physics springs beat fixed-duration
curves - they keep velocity when the target changes mid-flight, so interrupted
motion redirects smoothly instead of restarting. Keep bounce subtle (0.1-0.3); no
bounce for decisive actions (confirm, delete).

## Gesture physics

- Dismiss on velocity OR distance: a fast flick (~>0.11 px/ms) dismisses even from
  a small offset; otherwise dismiss only past a distance threshold, else snap
  back.
- Rubber-band at boundaries with logarithmic damping - never hard-clamp. Hard
  stops feel broken; friction feels physical.
- On drag start, capture the pointer so events keep routing to the element outside
  its bounds; track only the first pointer, ignore additional touches.

## Debugging motion

- Multiply all durations by 3-5x during development to expose hitches, wrong
  easing, and out-of-sync properties.
- Use the browser Animations panel (timeline, scrubbing, curve view) at 25%/10%
  playback.
- Test gestures and springs on a real device - touch behaves nothing like a
  trackpad.
- Review with fresh eyes the next day; run the interaction 10x fast - anything
  that grates on repetition needs work.

## Ship checklist

Smooth color transitions - correct easing for the interaction type - right
`transform-origin` - opacity and transform finish together - no layout shift -
respects `prefers-reduced-motion` - 60fps on a mid-range device.
