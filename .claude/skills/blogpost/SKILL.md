---
name: blogpost
description: >
  Write, review, and improve blog posts for a technical/developer audience. Use when the user
  wants to write a new post, improve an existing one, or get editorial feedback. Triggers on:
  "review this post", "improve this post", "write a blog post", "edit my post", "does this land",
  "is the structure right", "how should I open this", "what's wrong with this draft".
---

# Blog Post Skill

Technical writing for developers and practitioners. Assume the reader is smart and already knows
the landscape - they don't need convincing that the problem exists, they need the insight they
haven't heard yet.

## Step 0: Identify the post type

Before applying any editorial rules, identify what kind of post this is. The structure that works depends on the intent.

- **Argument post** - makes a claim and defends it. Arc: diagnosis → cause → prescription. The editorial ladder below applies fully.
- **Survey/case-study post** - documents a landscape, history, or set of examples, each teaching a lesson. No single thesis to hook with. The reader's payoff is the pattern across cases, not a buried conclusion to surface.
- **Tutorial/reference** - teaches a skill or documents a system. Different rules entirely (clarity, completeness, sequence).

If the post is a survey, skip to the survey-specific rules below. Don't try to restructure a survey as an argument post.

### Survey/case-study posts

The structural questions for a survey are different:

1. **Is the ordering intentional?** Chronological is a strong default for historical case studies - it shows how the field evolved, not just what happened. Thematic ordering works when lessons cluster better than timelines do.

2. **Are failure and success cases paired?** If the post has both "what went wrong" and "what worked" sections, the cases should mirror each other in order. Readers make the connection without the author pointing at it. OSI as the failure case, TCP/IP as the paired win - in the same position in each section.

3. **Does each case land its lesson explicitly?** Every case study should close with "The lesson: [one sentence]." Don't leave the reader to extract it.

4. **Are "how to improve" sections problem/solution pairs?** Bullet wishlists ("X would help") are weak. Each entry should name a live problem, give enough context to make it concrete, then propose at least one mechanism - with a named example if possible.

5. **Does every section earn its place?** Cut cases that repeat a lesson already made. An additional example of the same failure mode dilutes the one that made the point cleanest.

## The core editorial ladder (argument posts)

Work through these in order. The first failure point is the one to fix.

### 1. Is the sharpest insight the hook?

The most original thing the post says should be in the first two paragraphs - not buried after
sections of received wisdom the audience already knows. A reader who picks up a post titled
"How agile became waterfall" already believes agile has problems. Don't spend three sections
proving it to them.

**Test:** Read the post. What's the one sentence a reader could only have gotten here? Is it in
paragraph one or two? If not, restructure.

### 2. Does the structure follow diagnosis → cause → prescription?

For posts that argue a point, the natural arc is:
- **Diagnosis** - name the thing everyone has felt but not articulated
- **Cause** - trace how we got here (this is where the history/context lives, *after* the hook)
- **Prescription** - the actionable conclusion

History and context earn their place as explanation once the reader is hooked, not as a toll to
reach the point.

### 3. Are multiple solutions unified into one framing?

If the post proposes two or more solutions, they should be two sides of the same coin, not two
separate conclusions. Find the single framing that holds them together. Two half-conclusions
weaken both.

**Example from session:** "Automate the gates" and "bring back specialization" unified as:
specialists become platform teams, engineers become consumers of guardrail products. Automation
is *how* it works; specialization is *why* it works.

### 4. Does the closing contrast make abstract principles concrete?

A closing principle like "shift the guidance, not the burden" is powerful only if the post showed
both sides. Without the contrast, it's a question that sounds like an answer.

**Pattern:** Name the bad version and the good version explicitly.
- Bad: security checklist lands in the engineer's hands
- Good: security team encodes knowledge into a tool that enforces the rules for everyone

### 5. Does every section earn its place?

Cut sections that don't connect to the payoff. An interesting aside that breaks momentum right
before the solution lands is a net negative. Ask: does this move the reader toward the conclusion,
or is it a detour?

## Voice and style

- No em dashes (—). Use ` - ` (space-hyphen-space) instead.
- No filler transitions ("So,", "Now,", "Of course,").
- Short paragraphs. One idea per paragraph.
- Concrete examples anchor abstract claims. For every "this means..." follow with a named thing:
  a tool, a team, a real scenario.
- The analogy pattern: when introducing the core mechanic of a solution, ground it in a parallel
  the reader already knows. Designers → design systems. Frontend → component libraries. Then:
  "The same logic applies to security/compliance/etc."

## Common failure modes

**Buried lede** - The most original insight is in section 4 of 7. Fix: open with it, move
background underneath as "how we got here."

**Two conclusions** - The post proposes automation in section 6 and specialization in section 7
as if they're separate answers. Fix: find the single frame that makes them one answer.

**Abstract ending** - The final section floats to 30,000 feet without a concrete example to land
on. Fix: add one sentence that names the bad version and one that names the good version.

**History as preamble** - Sections 1-2 establish context the audience already has. Fix: compress
to 2-3 sentences, or move after the hook.

**Interesting but disconnected aside** - An observation that doesn't connect to the payoff
(e.g., "teams quietly do kanban anyway"). Fix: cut it or put it in a separate post.

## Workflow

**Reviewing an existing post:**
1. Read the full post.
2. Identify the post type (argument, survey, tutorial).
3. For **argument posts**: identify the sharpest insight, check if it's the hook, check structure against diagnosis → cause → prescription, check if multiple solutions are unified, check if the closing is concrete. Report as: "The post's strongest insight is [X]. It currently lands in [section]. The structural issue is [Y]. Proposed fix: [Z]."
4. For **survey posts**: check case ordering (chronological?), check failure/success pairing, check each case lands its lesson explicitly, check "how to improve" sections are problem/solution pairs not wishlists, check for redundant cases. Report as: "The ordering issue is [X]. The paired cases that need alignment are [Y]. The lesson missing from [case] is [Z]."

**Rewriting:**
- Preserve the author's voice. Restructure; don't rewrite for its own sake.
- The hook flip: take the sharpest section, promote it to the opening, compress the backstory
  into a bridge paragraph ("To understand how we got here...").
- After rewriting, run `npx markdownlint-cli --fix --disable MD013 --ignore node_modules -- <file>` then
  `npx markdownlint-cli --disable MD013 --ignore node_modules -- <file>` and fix any remaining errors.
