---
name: frontend-verify
description: >
  Measured accessibility and responsive gate for a web frontend you just built
  or changed. Runs axe-core (WCAG 2.0/2.1/2.2 A+AA plus best-practice) and a
  layout probe over every page x colour scheme x viewport width, walks the
  keyboard path, and reports counted results instead of an eyeball opinion. Use
  this before calling any frontend work done, and whenever the user asks to
  check accessibility, run an a11y audit, test dark mode, check mobile or
  responsive behaviour, find what breaks at some width, verify contrast or
  touch-target sizes, or check keyboard and screen-reader support. Triggers on
  "is it accessible", "a11y", "axe", "WCAG", "contrast", "screen reader",
  "keyboard navigation", "does it work on mobile", "check the breakpoints",
  "responsive check", "does it break at 320", "test all viewports", "does dark
  mode work". Also run it unprompted after building or restyling a page, a
  layout, or a component. For how to FIX what it finds, read
  ui-ux-best-practices; for aesthetic direction, hallmark. This skill only
  measures and gates.
---

# Frontend Verify

A responsive layout that was checked by looking at it is a layout that breaks
at the width nobody looked at. This skill replaces the eyeball with a count:
*84 page/width combinations, zero violations* is a claim someone can re-run.

Run it as a **gate** - the work is not done until it passes, or until a
remaining failure is written down with the reason it was accepted.

## 1. Set up (once per repo)

```sh
npm i -D playwright axe-core && npx playwright install chromium
```

The pages need to be reachable. A dev server is ideal; a static build works
over `file://`; `npx serve dist` if the pages fetch anything.

The script resolves both packages from the current directory first, so a repo
that already has Playwright needs no second install. For a repo that should not
carry them as dev dependencies, run the same install once inside
`~/.claude/skills/frontend-verify/` and every repo can use it.

To confirm the probes still detect what they claim (rules and browsers move),
run the two fixtures in `scripts/selftest/`. `bad.html` must produce a failure
of each kind - axe violation, horizontal scroll, wrapped nav label, over-long
measure; `good.html` must produce none, and must report `skipLandsFocus` as
`main#main`.

## 2. Run the gate

```sh
node ~/.claude/skills/frontend-verify/scripts/verify.mjs \
  --urls http://localhost:8080/,http://localhost:8080/pricing/ \
  --schemes light,dark
```

Options: `--widths` (default 320,360,375,414,600,768,834,1024,1280,1440,1920,2560),
`--schemes` (default light,dark), `--theme-attr data-theme` when a class or
attribute switches the theme rather than `prefers-color-scheme`, `--max-ch`
(default 78), `--out`. Exit code 1 means at least one failure. Full detail
lands in `frontend-verify.json`.

Enumerate **every** page, not a sample - the one page you leave out is where
the untested partial lives. Both colour schemes: a contrast failure usually
exists in only one of them.

What it fails on: any axe violation; horizontal scroll; an element past the
viewport edge; a nav, footer or button label wrapping to two lines; a body text
block wider than 78 characters; an uncaught page error.

## 3. Check what the tool cannot see

axe finds roughly a third of WCAG issues. These need you, at 375 and 1280:

- **Keyboard path** - read the recorded tab order in the JSON. It should follow
  the visual order, every stop should have a visible ring, and a skip link must
  actually land focus in `<main>` (which needs `tabindex="-1"` for that to
  work - the script reports where focus went).
- **A mobile menu** - opens with Enter, its links are reachable in order, focus
  is not stranded when it closes.
- **`lang` on foreign-language content** - a German legal page inside an
  English site needs `lang="de"` on that region, or a screen reader reads it in
  the wrong voice. axe only checks `<html lang>`.
- **`role="list"` on lists with `list-style: none`** - Safari drops list
  semantics, so the count ("3 items") is never announced.
- **`scroll-margin-top`** under a sticky header - otherwise the header covers
  whatever just received focus or was jumped to by anchor.
- **Meaning carried by colour alone** - a red border with no text or icon.
- **Motion** - `prefers-reduced-motion` actually honoured.

## 4. Fix the cause, not the measurement

Raise the token to 4.5:1; do not exclude the rule. Give the link a 24px target;
do not widen the failure threshold. Inline links inside running prose keep the
WCAG target-size exception - that is a real exemption, not a workaround.

`left: -9999px` for a skip link is a layout escape, not a hiding technique -
use a clip-path pattern so focus can bring it back.

Re-run the gate after fixing. A fix at 375 regularly breaks 1440.

## 5. Record each breakpoint with its reason

In `DESIGN.md` (or the nearest design doc), write one line per breakpoint
saying what content forced it:

```md
- 48rem - the spec table needs two columns; below this it stacks.
- 60rem - the nav labels stop fitting beside the logo.
```

A breakpoint with a stated reason makes the next change argue with the reason.
A bare `@media (max-width: 768px)` makes it guess.

## 6. Report

State counts, then what you fixed, then what you left. Keep the last part -
an accepted failure with its reasoning is a decision; the same failure unsaid
is a bug you shipped.

```md
## Accessibility
axe-core (WCAG 2.0/2.1/2.2 A+AA + best-practice) reports zero violations on all
seven pages, in both colour schemes, at 375 and 1280.

- `--color-neutral` was 3.98:1 - the only contrast failure, and it carried the
  pending-price text. Now above 4.5:1.
- Nav, footer and TOC links were 22px tall, under the 24px target minimum.

## Coverage
84 page/width combinations (320 ... 2560): no horizontal scroll, no element
past the viewport, no nav label on two lines, no body block over 78 characters.

## Left alone
The mobile menu is `<details>` and does not close on Escape. The Popover API
gives that plus click-outside, but browsers without it lose the nav entirely -
worse on an old iPhone than a missing shortcut at phone width. Recorded in
TODO.md as a revisit.
```

Never report a pass you did not measure. "Should be fine at mobile" is the
sentence this skill exists to delete.
