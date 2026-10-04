---
name: website-structure
description: >
  Content and information-architecture rules for a company or product website
  - what a page should say, how to say it, and what to leave out. Covers
  pricing/legal copy accuracy (never publish a derived number that doesn't
  check out, don't guess at unresolved tax/legal treatment), section-level
  relevance (cut sections that carry no decision-relevant information),
  closing-CTA framing (lead with the outcome, don't restate a mechanism the
  reader already read), and content hygiene (delete copy when you delete the
  section that rendered it). Use whenever the user is writing or editing copy
  for a marketing, landing, product, or pricing page; deciding what sections
  a company site needs or should cut; reviewing pricing, plan, or legal copy
  for accuracy; or asking what a page should or should not say. Distinct from
  hallmark (visual design, UI microcopy) and ui-ux-best-practices (layout and
  interaction craft) - this skill is about the truthfulness and relevance of
  the content itself, not how it looks or behaves.
---

# Website Structure

What a company or product site says, and what it leaves out. Complements
`hallmark` (visual design) and `ui-ux-best-practices` (interaction craft) -
this is about information architecture and truthfulness of content, not
appearance.

## Accuracy is the floor

A published number on a pricing or product page is read as a fact the
company stands behind, not a rough gesture.

- **Check the arithmetic before publishing a derived claim.** "15% of a €5
  fee" is €0.75, not "about one euro." If a sentence does math the reader
  can redo, redo it yourself first.
- **State the basis, or state nothing.** "Gross" vs "net," "final" vs
  "placeholder," "per account" vs "per site" - pick the one that's true and
  say it. A number with no stated basis invites the reader to assume the
  most favorable one, which is rarely the honest one.
- **Never invent stats, customer counts, or testimonials.** Real, explicitly
  marked as a placeholder, or absent - never blended in as fact.
- **When the real rule is genuinely unresolved** (cross-border VAT,
  jurisdiction-dependent tax, a regulatory status not yet confirmed), don't
  guess at confident-sounding copy to fill the gap. Either state only what's
  certain, or say nothing - a wrong confident claim is worse than a visible
  gap, and both are worse than published misinformation reaching a customer.

## Placeholders don't belong in the reader's view

A "placeholder, not final" caveat sitting in customer-facing copy is itself
a liability: it's easy to forget to remove when the real number lands, and
until then it reads as unfinished work on a live page. Track placeholder
status in the data layer and the project's own TODO/issue tracker - visible
to whoever ships the real number - not as a sentence the customer reads.
The page should look finished even when a number behind it isn't yet real;
the incompleteness is the team's problem to track, not the reader's problem
to be warned about.

## Every section earns its place

Cut a section if it gives the reader nothing to decide or act on - an
unpublished table that's all placeholders, a mechanism explained three times
in three sections, a caveat nobody asked for. A technical buyer who wants
full detail still doesn't want repetition; density is not the same as
completeness. If removing a section would lose no real information, remove
it before asking whether to keep it.

## Closing CTAs lead with outcome, not a restated mechanism

By the time a reader hits the closing call-to-action, they've already read
the mechanism (the limit, the fee, the flow) in the body above. A CTA that
restates it is filler dressed as a summary. Lead the headline with the
outcome the reader gets - what changes for them - and let the body carry
the one supporting fact, not a re-explanation.

- Weak: "The limit is yours. A new account's limit sits on the quota, so
  usage never bills you before you decide it should."
- Stronger: "No bill you didn't choose. A small site pays one flat annual
  fee. Above it, you set the limit yourself."

## Don't describe internals the reader can't act on

A cost or process breakdown shown to a customer should describe what the
money buys, not the company's internal structure. "Accounting, insurance,
and the filings that keep a company legal" tells the reader what a line
item is for. Naming salaries, staff, or "what's left for the people who run
it" turns a cost breakdown into an internal HR conversation the reader has
no stake in and didn't ask to see.

## No implementation-detail claims that can go stale silently

"Loads no scripts," "never goes down," "always under 100ms" - claims about
how the thing is built, not what it does for the reader. These can break
in a refactor nobody remembers to reflect in the copy, and then the page is
lying without anyone deciding to lie. Say what the product does or
guarantees, not the mechanism that happens to produce it today.

## When a section stops rendering, its copy goes with it

If a template section is deleted or gated off, the markdown/data that fed it
becomes dead content - remove it in the same change. An unused paragraph
sitting in a content file is exactly as much debt as unused code: the next
person who edits the file can't tell if it's meant to come back or if it
was simply forgotten.

## Business-consequential copy changes aren't "just wording"

A request to reword a pricing, tax, or legal sentence can be a request to
change what's actually true or actually charged, not just how it's phrased.
Before editing, check whether the current numbers already embed the old
claim (e.g., a "gross, VAT included" price where VAT is already baked into
the digits) - if so, flag that the edit changes real numbers, not just
prose, before making it. When the correct real-world answer is unclear (tax
jurisdiction, legal status), say so and ask rather than picking a plausible
answer and writing confident copy around it.
