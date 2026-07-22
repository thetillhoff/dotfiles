# Mobile & Touch

Responsive isn't just a narrower layout - touch input, thumb reach, and mobile
context change the interaction model. Design for the hand and the environment,
not only the viewport width.

## Touch targets & reach

- **Minimum target 44×44 px** (Apple HIG) / 24×24 CSS px is the WCAG 2.2 AA floor;
  aim for 44+. Extend a small visual control's hit area with padding or a
  pseudo-element rather than shrinking the tap zone.
- **≥ 8 px between adjacent targets** so fat fingers don't hit the wrong one.
- **Thumb zones**: the bottom and center are easy to reach one-handed; top corners
  are hard. Put primary actions and nav within thumb reach (bottom bar), not
  pinned to the top. Destructive actions out of the easy-reach arc.

## Input must not depend on hover or precise pointers

- **No hover-only affordances** - touch has no hover. Anything revealed on
  `:hover` (menus, tooltips, actions) must also be reachable by tap/focus. Gate
  hover-only enhancements behind `@media (hover: hover) and (pointer: fine)`.
- Detect capability with `pointer: coarse` (touch) vs `fine` (mouse), not screen
  width - a touchscreen laptop is wide but coarse.
- Give larger touch targets and generous spacing under `pointer: coarse`.

## Get the right mobile keyboard

The on-screen keyboard is chosen by input attributes - set them so the user isn't
fighting the wrong one:

- **`type`**: `email`, `tel`, `url`, `number`, `search`, `date`/`time` - each
  summons the right keys and native pickers/validation.
- **`inputmode`**: `numeric` (PINs/codes, digits only), `decimal`, `tel`, `email`,
  `url`, `search` - use when `type` must stay `text` but you want a specific
  keypad.
- **`enterkeyhint`**: label the Enter key (`search`, `go`, `next`, `done`, `send`).
- **`autocomplete`** tokens (`name`, `email`, `street-address`, `one-time-code`,
  `cc-number`…) so autofill and SMS-code suggestion work - a huge mobile
  time-saver and a WCAG 1.3.5 item.
- `autocapitalize`/`autocorrect` off for codes, usernames, and case-sensitive
  fields.

## Viewport & device realities

- **`<meta name="viewport" content="width=device-width, initial-scale=1">`** -
  the baseline for responsive rendering. Do **not** disable zoom
  (`user-scalable=no` / `maximum-scale=1`) - it breaks accessibility.
- **Safe-area insets**: on notched/rounded phones, pad fixed top/bottom UI with
  `env(safe-area-inset-*)` (needs `viewport-fit=cover`) so a bottom bar isn't
  under the home indicator.
- **`100dvh`, not `100vh`** - `vh` doesn't account for the mobile URL bar and
  clips full-height layouts (see web-implementation.md).
- Test with the on-screen keyboard open - it shrinks the viewport and can cover
  the field being typed into; keep the active input scrolled into view.

## Mobile interaction patterns

- Collapse top nav to a menu button below a breakpoint; a bottom-tab bar for 3-5
  primary destinations (see nav layouts in web-implementation.md).
- Prefer native controls (`<select>`, `<input type=date>`) on mobile - they open
  optimized full-screen pickers for free and beat most hand-rolled widgets.
- Respect momentum scrolling; use `scroll-snap` for carousels; avoid hijacking
  scroll or trapping it in nested scrollers.
- Account for one-handed use, glare, and interruptions - mobile users are often
  distracted; keep flows short and resumable.
