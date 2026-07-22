# UI Pattern Conventions

Framework-agnostic component and flow conventions, distilled from where the major
design systems **converge** (Atlassian, Fluent 2, Carbon, Primer, Ant, Lightning,
GOV.UK, USWDS). Convergence across 3+ systems is a durable rule, not one vendor's
opinion. Use as a decision reference when building a specific component or flow.

- [Component conventions](#component-conventions) - buttons, messages, modals,
  tables, tabs, menus, tooltips, pagination, empty states, loading.
- [Form & service-design flow patterns](#form--service-design-flow-patterns) -
  gov-grade flows: one-thing-per-page, error summary, check-answers, task list,
  field-type inputs.

## Component conventions

### Buttons & action hierarchy

- **At most one primary/high-emphasis button per view (or per region).** Extra
  primaries dilute hierarchy. Secondary is the workhorse - most buttons should be
  secondary.
- **Emphasis ladder**: primary → secondary → tertiary/ghost → subtle/link, in
  decreasing emphasis. Fill level *is* the emphasis level (filled → outline →
  text). Size signals context (sm/default/lg), **not** importance.
- **3+ actions in one place → collapse the secondary ones into an overflow /
  kebab (`⋯`) menu.** Don't line up five equal buttons.
- **Destructive/danger** is its own variant, reserved for irreversible acts,
  never the default focus, always paired with a confirm step.
- Primary sits **rightmost** in a Western-reading button group; one primary per
  group.

### Message channel routing (the strongest convergence)

Match **scope + urgency + persistence** to the channel - don't pick by looks:

| Channel | Use when | Persistence |
| --- | --- | --- |
| **Inline message** | Feedback tied to a specific field/section, in context | Persists |
| **Toast / flag** (corner/top, transient) | Acknowledge a *completed user action*, low importance | Auto-dismiss ~3-5 s; **one at a time**; always a manual close too |
| **Notification** (corner, richer) | Longer/complex or app-pushed events, may carry actions | Manual or long auto; set persistent if actionable |
| **Banner** (full-width, top) | *System-level* state (outage, maintenance, data loss); pushes content down, not an overlay | Usually not dismissible; one at a time |
| **Modal** | Message requiring immediate action / blocking decision | Forced choice |

- **Anything that requires a user action must persist - never auto-dismiss it**
  (WCAG 2.2). Toast auto-dismiss is for informational acks only.
- **Banner = system state, never action-feedback.** Don't toast an outage; don't
  banner a "saved ✓".
- Fixed status vocabulary: **info / success / warning / error** - reuse
  everywhere, always icon + text (never color alone). Warning = recoverable /
  needs attention; error = failed / blocked.

### Modal / dialog

- **Modal only for a focused must-finish task or a decision needing immediate
  attention** - it's a hard interrupt. Never for content that could be its own
  page or an inline expansion.
- **Keep it single-purpose; never nest or stack modals.**
- **Alert/confirmation dialog** = the subset reserved for potential loss (unsaved
  changes, destructive confirm).
- **Forced-choice "prompt"** (no close icon, must pick) vs a dismissible modal -
  use forced-choice only for genuinely blocking system decisions.
- Dismissal contract: Esc + an explicit footer button always; outside-click
  dismiss for modal only (a non-modal helper dialog like find/replace must *not*
  close on outside-click). **Trap focus while open; return focus to the trigger
  on close.** Primary action rightmost in the footer.

### Table / data table

- **Four distinct states, never one blank box**: loading (skeleton mirroring the
  real layout), empty-first-use, no-results-from-filter, error. Each gets its own
  copy and next-step action. An explicit empty state is mandatory.
- **Sort**: only the active column shows a directional arrow; 3 states
  (none/asc/desc); others reveal the affordance on hover.
- **Selection surfaces a batch-action bar**; while it's active, disable per-row
  inline actions (Carbon) so the two action scopes don't compete.
- Text left-aligned, numbers right-aligned. Density is a first-class control
  (compact/default/comfortable). Sticky header + pinned first/last column for
  wide/long tables. Pagination bottom-right, integrated. Tables are a
  desktop-density pattern - rethink for mobile.
- **Distinguish rows** with zebra striping or subtle row borders, never color
  alone. **Virtualize** lists beyond ~50 rows (render only what's on screen) to
  keep scrolling at 60fps.

### Tabs

- **Tabs switch peer views within one context** - never sequential steps (use a
  stepper) and never navigation between unrelated pages (use a menu).
- **Never hide critical/must-see info behind a tab** - it's invisible until
  clicked. One tab always selected; selection persists per session.
- Don't nest tabs; if they overflow/scroll, rethink the IA. Line tabs = sections
  of a page; card tabs = many closeable doc-like views.

### Menu vs select

- **Menu = a list of actions/commands. Select/dropdown = choosing a value for a
  form.** Don't conflate them.
- Group and divide long menus; destructive items last, visually separated.
  Reposition to stay in the viewport (flip/nudge). Keep labels short.

### Tooltip vs popover

- **Tooltip holds only non-essential, plain text.** Never essential info,
  actions, or rich/formatted/interactive content - that's a **popover**.
- Additional, not redundant - don't just repeat the visible label. Must trigger
  on **hover *and* focus** and be keyboard/touch reachable (hover-only excludes
  keyboard and touch users). For a disabled control, say how to enable it.

### Pagination vs infinite scroll

- **Pagination** for large, addressable sets users navigate/bookmark/jump within
  (data tables especially). Show total count + current range; let users set page
  size (offer the size-changer only past ~50 items); hide controls on a single
  page.
- **Infinite scroll** only for exploratory/endless feeds; it sacrifices the
  footer and a sense of position. Keep crawlable/bookmarkable URLs behind any
  "load more".

### Empty states

- **An empty state is a designed state, not a blank.** Always tell the user what
  to do next (a CTA or guidance). The message/description is the required part.
- Distinguish the types - first-use, no-results, error - each needs different
  copy and action. First-use doubles as onboarding ("create your first X").
  No-results suggests adjusting or clearing filters.
- Right-size the treatment: full illustration when it's the whole page; compact
  message when repeated or many per screen; skip the illustration if it adds no
  understanding.

### Loading & skeletons

- **Skeleton over spinner for the first load of content-rich areas** (lists,
  cards, tables) - shape it to mirror the final layout so it reduces perceived
  wait. Spinner is fine for short/in-place/subsequent refreshes; progress bar
  when duration is knowable.
- Don't skeleton tiny/instant elements - it flickers. A shimmer distinguishes
  "loading" from "genuinely empty".

### Form field conventions

- **Mark the minority.** If most fields are required, mark the *optional* ones;
  if most are optional, mark the *required* ones. Never mark both.
- **Helper text (persistent, before input) and error message (after validation)
  are separate slots** - don't conflate. Error = red border + icon + text
  together, placed directly below the field, tied to it.
- **Validate on blur per field, then re-validate on change once it has errored.**
  Validating every keystroke from the start is noisy; blur-first is the durable
  default. (Server-side validation still authoritative.)
- Vertical layout (label above input) is the mobile-safe default.

## Form & service-design flow patterns

Gov-grade flows (GOV.UK, USWDS, NHS) - proven for high-stakes, must-not-fail,
accessibility-first services. Adopt for any long or important form.

- **One thing per page.** Ask a single question (or one tightly-related group)
  per page. Comprehension and completion rise; each page's `<h1>` *is* the
  question, and the field's label/legend doubles as that question.
- **Error summary.** On a failed submit, render a summary box at the **top**
  listing every error as links that move focus to the offending field - *and*
  show each field's own inline message. Move keyboard focus to the summary, and
  prefix the page `<title>` with "Error:". This is the single biggest form-a11y
  upgrade beyond plain inline validation.
- **Check-answers page.** Before final submit, show all answers grouped, each row
  with a "Change" link back to that question. Reduces errors and anxiety.
- **Confirmation page.** After submit, a success panel with what happened, a
  reference number, and "what happens next" - never just bounce back to a list.
- **Task-list pattern** (non-linear, resumable): for long multi-section services,
  a landing page listing sub-tasks each tagged Completed / In progress / Cannot
  start yet. Distinct from a linear progress tracker (see SKILL.md §7) - use it
  when sections can be done in any order across sessions.
- **Eligibility gate / start page.** State what the service does, who it's for,
  and how long it takes before the user commits; filter out ineligible users up
  front before they invest effort.
- **Field type drives the input, not a generic text box:**
  - **Dates the user knows** (birthdays, known past dates) → three separate
    day/month/year text fields, **not** a date picker. Reserve pickers for dates
    being chosen or looked up (appointments).
  - **Names** → one full-name field by default; don't split first/middle/last
    without a real need.
  - **Addresses** → allow manual entry, don't over-validate, support
    international/non-standard formats.
  - Add `autocomplete` tokens on personal-data fields so browsers and AT fill
    them; don't force re-entering info already given in the same process
    (WCAG 2.2 redundant-entry).
- **Framing**: start from user needs, not org structure; reassure anxious/
  first-time users about what data is for and privacy at the point of asking;
  never a dead end - always offer an assisted/offline route.
