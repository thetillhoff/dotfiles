# Interactive Component Behavior Contracts

The keyboard, focus, ARIA, and dismiss behavior every interactive component must
satisfy - the durable part that headless UI libraries (React Aria, Radix, Ark,
Headless UI, Base UI) encode. Their code is React; the **behavior** below is
framework-agnostic and ports directly to vanilla JS, web components, or
htmx-swapped markup.

**Top takeaway:** correct overlay and rich-input accessibility (focus trapping,
`aria-activedescendant` vs roving tabindex, dismiss layering, collision-aware
positioning) is genuinely hard and easy to get subtly wrong. **Source it from a
primitive rather than hand-rolling**, and prefer native elements
(`<button>`, `<input type="radio|checkbox">`, `<dialog>`, `<details>`) which give
most of this for free. The canonical contract is the **WAI-ARIA Authoring
Practices Guide (APG)**, <https://www.w3.org/WAI/ARIA/apg/patterns/>; the libs
above are faithful implementations of it.

## Two focus models (the core distinction)

- **Roving tabindex** - focus physically *moves into* the widget; one child has
  `tabindex="0"`, the rest `-1`; arrows move focus. Used by menu, tabs, radio
  group, and (optionally) listbox. `Tab` exits the whole widget.
- **`aria-activedescendant`** - DOM focus *stays put* (e.g. on a combobox input);
  the "active" child is pointed at by id. Used by combobox and grid-like widgets.
  Getting this wrong (moving real focus into the popup) is the single most common
  combobox bug - typing breaks and AT announces nothing.

## Dialog / modal

- `role="dialog"` + `aria-modal="true"`, labeled by `aria-labelledby`.
- Open → move focus in; **trap** focus; close → **return focus to the trigger**.
- Dismiss on `Esc` and backdrop/outside click.
- Gotcha: `aria-modal` alone does *not* reliably hide the background from screen
  readers - also make the background `inert` (or `aria-hidden`), or AT wanders
  behind the modal.

## Alert dialog

- Same as dialog but `role="alertdialog"`; description announced assertively.
- Focus the **least destructive** action (Cancel), never Confirm.
- **No light dismiss** - outside click doesn't close, `Esc` often disabled; it
  demands an explicit choice. That's the key delta from a plain dialog.

## Menu / dropdown (menu of actions)

- `role="menu"` + `role="menuitem"` (or `menuitemradio`/`menuitemcheckbox`);
  trigger has `aria-haspopup="menu"` + `aria-expanded`.
- Roving tabindex. `↑`/`↓` move, `Home`/`End` jump, type-ahead to first letter,
  `Enter`/`Space` activate, `Esc` closes + returns focus to trigger, `→`/`←`
  open/close submenus. `Tab` closes the whole menu (menu items are *not* tab
  stops).
- Gotcha: hand-rolled versions leak `Tab` between items; submenu parents must
  keep `aria-haspopup` and toggle `aria-expanded` in sync.

## Listbox / Select

- `role="listbox"` + `role="option"` with `aria-selected`; `aria-multiselectable`
  for multi.
- Holds a **persistent value** (vs a menu's transient actions) - don't build a
  value picker out of `menuitem`.
- Focused option ≠ selected option; they're distinct states. Roving focus in
  multi-select must not silently change the committed value.
- `↑`/`↓`, `Home`/`End`, type-ahead; single-select may select on move,
  multi-select toggles with `Space`, `Shift+arrows` extends.

## Combobox / Autocomplete

- Input `role="combobox"`, `aria-expanded`, `aria-controls`→popup,
  `aria-autocomplete`; popup is a `listbox`.
- **DOM focus stays on the input**; highlighted option indicated via
  `aria-activedescendant` (see focus models above) - never move focus into the
  list.
- `↓`/`↑` open + move active option, `Enter` commits, `Esc` closes (second press
  clears), printable chars filter.

## Tabs

- `role="tablist"` > `role="tab"` (`aria-selected`, `aria-controls`); each
  `role="tabpanel"` `aria-labelledby` its tab, `tabindex="0"` if it has no
  focusable content.
- Roving tabindex across tabs; the panel is a *separate* single tab stop.
- `←`/`→` (or `↑`/`↓` when `aria-orientation="vertical"`), `Home`/`End`.
- **Automatic activation** (selects on arrow-focus) vs **manual** (arrow moves
  focus, `Enter`/`Space` activates) - use manual when activating is expensive
  (loads data).

## Accordion / Disclosure

- Disclosure: a `<button>` with `aria-expanded` + `aria-controls`→region; region
  hidden with `hidden`/`display:none`, not just visually.
- Accordion: multiple disclosures; panels `role="region"` `aria-labelledby` their
  header; optional `↑`/`↓`/`Home`/`End` between headers.
- Gotcha: collapsed content must be truly hidden from AT and tab order - hiding
  with `opacity`/`height:0` while leaving it focusable is the classic bug.

## Tooltip

- `role="tooltip"`, referenced by the trigger's `aria-describedby`.
- Trigger on hover **and** focus; dismiss on `Esc`; stays open while hovering the
  tooltip itself (WCAG 1.4.13). Delay on show, little/none on hide.
- Non-essential, non-interactive content only - no links/buttons/critical info
  (that's a popover).

## Popover

- `role="dialog"` (or a labeled region); trigger `aria-expanded` +
  `aria-haspopup`.
- **Non-modal**: move focus in on open, but background stays interactive; return
  focus to trigger on close. (A modal popover = treat as a dialog.)
- Light dismiss: outside click, `Esc`, and focus leaving all close it.
- Holds real focusable content (unlike a tooltip) - putting interactive content
  in a `role="tooltip"` is the classic error.

## Switch / Checkbox / Radio group

- Switch: `role="switch"` + `aria-checked` (no indeterminate); `Space` toggles.
- Checkbox: `role="checkbox"` + `aria-checked` incl. `"mixed"`; `Space` toggles.
- Radio group: `role="radiogroup"` > `role="radio"`; **roving tabindex** - the
  group is *one* tab stop, arrows move + select, `Tab` exits.
- Gotcha: making each radio individually `Tab`-focusable is wrong. Prefer native
  `<input type="radio|checkbox">` - it's all free.

## Slider

- `role="slider"` on the **thumb**; `aria-valuenow`/`min`/`max`, and
  `aria-valuetext` when the number isn't self-explanatory ("$50", "Medium");
  `aria-orientation` for vertical.
- `←`/`↓` decrease, `→`/`↑` increase, `Home`/`End` to bounds, `PageUp`/`PageDown`
  large step. Multi-thumb = each thumb its own slider bounded by its neighbors.
- Gotcha: touch/mobile AT support is weak (needs synthesized key events) -
  provide a real number-input fallback.

## Toast / live region

- Declare the live region **before** inserting messages: `role="status"` /
  `aria-live="polite"` for normal, `role="alert"` / `aria-live="assertive"` for
  urgent.
- Never steal focus or trap; keep out of tab order unless it carries an action;
  pause auto-dismiss on hover/focus.
- Gotcha: AT only announces changes to a region that **already existed** in the
  DOM - the empty live-region container must be present at page load.

## Floating element positioning (menus, popovers, tooltips, comboboxes, selects)

- Compute placement against the trigger - don't assume down/right.
- **Flip** to the opposite side when the preferred side lacks space; **shift**
  along the axis to stay in the viewport; **clamp** size to available space and
  let content scroll rather than overflow.
- Render in a portal / top layer (or the native `popover` attribute /
  anchor-positioning) to escape `overflow:hidden`, `z-index`, and `transform`
  clipping - but preserve the AT relationship via `aria-controls` /
  `aria-activedescendant`. Recompute on scroll and resize.
