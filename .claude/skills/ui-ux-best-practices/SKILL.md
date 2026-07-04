---
name: ui-ux-best-practices
description: >
  Battle-tested UI and UX principles for designing, reviewing, or fixing any
  user-facing interface - web, mobile, or app - and for cutting overwrought
  "AI slop" design back to the least design necessary. Covers layout, hierarchy,
  typography, color, interaction feedback, forms, navigation, and accessibility,
  grounded in the canonical usability frameworks (Nielsen's heuristics, Tog's
  principles, Gestalt laws). Use this whenever building a screen, page, form, or
  component; critiquing, auditing, or evaluating an existing UI against usability
  heuristics - "why does this feel off", low conversion, high form drop-off, an
  accessibility review; choosing spacing, color states, dark-mode contrast, or
  type scales; or stripping back generic gradient-and-shadow AI slop. Also
  triggers on "UX", "usability", "user flow", "make it intuitive", "is this good
  UI". This is the principles layer and applies on top of, not instead of,
  frontend-design (aesthetic direction) and interface-kit (implementation craft)
  - invoke it alongside them, never defer to them. NOT for writing copy or
  content (that is copywriting), charts/plots/data visualization (use dataviz),
  a design-system spec document (use design-system), or a dense single-operator
  internal/admin tool (use operator-ui).
---

# UI & UX Best Practices

Design that gets out of the way. If the user does not have to fight it, it
becomes invisible. Every choice below serves that: reduce effort, remove
surprise, make the next action obvious.

**How to use:** treat the sections as a checklist when building, and as a
critique lens when reviewing. For the named theory (Nielsen's 10 heuristics,
Tog's principles, Gestalt laws, color schemes, layout patterns) consult
`references/frameworks.md` - cite by name when justifying a decision.

## 1. Start with the user, not the screen

Before laying anything out: who is the user, what is their goal, what is the
flow that gets them there? Sketch the **user journey** first; the UI is just the
path. Design each screen around the one thing the user came to do.

- **Progressive disclosure** - ask one thing at a time, not everything at once.
- **Above vs below the fold** - be deliberate about what is seen without
  scrolling. Put the primary action and value there.
- **Familiar patterns** - do it the way most products do it. Novelty in
  mechanics is a tax; spend it only where it is the point.

## 2. Layout & hierarchy

Guide the eye. A viewer should know where to look first, second, third without
being told. Three levers, applied together:

- **Size & weight** - important things are bigger and bolder.
- **Contrast** - important things stand apart from their surroundings.
- **Spacing** - important things get room; grouping conveys relationship.

Rules of thumb:

- **Whitespace is breathing room**, not wasted space. Do not crowd. Under-design
  before you over-design - shadows, borders, and effects pile up into noise.
- **Strict grid** - align everything to a spacing system (e.g. an 8pt grid).
  Alignment reads as competence; drift reads as sloppy.
- **Proximity** - things that belong together stay together (Gestalt).
- **Cards** to show where a discrete item begins and ends. **Split screens** for
  two items of equal hierarchy. **Grids/tables** for uniform collections.
- **F-pattern** (text-heavy pages) and **Z-pattern** (sparse landing pages)
  match how eyes actually scan - place key elements on those paths.
- **Perspective / flow** - position elements where the flow expects them
  (submit at the end of a form, not the top).

## 3. Typography

- **Max two font families.** More fragments the page.
- **Type conveys tone** - heavy/bold vs light/sleek, classic vs modern. Pick
  intentionally.
- **Readability first** - generous size, high contrast, comfortable line length.
- Define a **type scale** (sizes, weights, line-heights) and reuse it; do not
  set sizes ad hoc.

## 4. Color

- Build a **palette from a scheme**: monochromatic, analogous, complementary,
  split-complementary, triadic, or tetradic. Do not pick colors at random.
- **Color as a tool** - success/warning/error carry meaning; never rely on color
  alone (colorblind users need a second cue: icon, label, shape).
- **Contrast** must pass in **both light and dark mode**. Detect the user's
  system preference and support both - and always verify both, they break
  independently.

## 5. Interaction & feedback

Every tap, click, or drag gets a response - a subtle one is usually enough. The
absence of feedback reads as "broken".

- **Immediate acknowledgment** (<~50ms for the visible reaction). Loading
  spinners for waits, hover/pressed states, success toasts.
- **Clickable things look clickable** - interactive elements must stand out
  (color, emphasis). Links are underlined and blue-ish by convention; do not
  strip the affordance.
- **Icons clarify, not complicate** - keep a text label beside an icon in most
  cases; an icon alone is a guessing game.
- **Smart defaults** - pre-fill and pre-select the likely choice. Do not
  autoplay media. Defaults must be replaceable.
- **Keyboard shortcuts** for frequent/expert actions; keep them discoverable but
  out of a beginner's way.

## 6. Forms & input

Forms are where users quit. Reduce effort and never punish.

- **Validate per-input, inline, as they go** - tell the user about a problem on
  the field itself, not only after they hit submit.
- **Never clear a field on error.** Losing typed data is the fastest way to lose
  a user.
- **Accessible label on every input** (not placeholder-as-label). Placeholder
  text is a hint, not a substitute for a label.
- **Recognition over recall** - offer suggestions, autocomplete, and pickers
  instead of a blank box the user must fill from memory.
- **Clear call-to-action**: verb + noun ("Submit form", "Create account"), not a
  bare "Submit" or "OK".

## 7. Navigation

- **Visible and consistent** - users should always know where they are and how to
  get back. Highlight the current location; use breadcrumbs where depth warrants.
- **Logo in the nav links to home** (expected everywhere; its absence surprises).
- **User control & freedom** - always provide undo, cancel, and a clear exit.

## 8. Accessibility (non-negotiable)

- **Semantic HTML** - use the right element for the job; it gives you keyboard
  and screen-reader behavior for free.
- **ARIA labels** where semantics are not enough; **alt text** on every
  meaningful image.
- **Scalable, high-contrast fonts**; respect user zoom and reduced-motion.
- **Full keyboard navigation** - everything reachable and operable without a
  mouse.

## 9. Design system

Once past a couple of screens, stop deciding the same thing twice. Define once,
reuse everywhere - typography scale, color usage, button styles & states,
spacing, border-radius, animation speed, and shared components (tables, cards,
grids). This is what makes a product feel like one product. See
`references/frameworks.md` for what a design system contains.

## 10. Question the status quo - least design necessary

Default to the least design code that does the job. Every element, style, and
effect must earn its place by serving the user's goal; if removing it changes
nothing for the user, remove it.

Be especially skeptical of **AI design slop** - the generated-looking defaults
that pile on because they are easy to add, not because anyone needs them:
gratuitous gradients and glassmorphism, drop shadows on everything, decorative
hero blobs and floating icons, purple-to-pink gradients, emoji-as-feature-icons,
three-column "feature" grids that say nothing, animation for its own sake,
rounded-everything, and copy like "Elevate your workflow". These read as
templated and untrustworthy, and they add cognitive load.

Before shipping any element, ask:

- Does the user's task need this, or does it just fill space?
- Would a plainer version work as well or better?
- Is this here because it is genuinely useful, or because it looked "designed"?

A native control beats a custom one. A plain button beats a styled one when the
plain one communicates the same thing. Restraint is the tell of a real designer;
excess is the tell of a generator. When unsure, cut it - you can always add it
back if a real need appears.

## The short version

Keep it simple. Stay consistent. Make navigation obvious. Mobile-first and
responsive. Favor readability. Reduce effort at every step. Don't reinvent
familiar patterns. When in doubt, remove something.
