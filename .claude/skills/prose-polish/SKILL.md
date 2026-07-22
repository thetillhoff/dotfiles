---
name: prose-polish
description: Use when a markdown document (blog post, README, doc, guide) needs sentence-level style improvements: hard-to-read sentences, passive voice, adverbs, qualifiers, word complexity, or readability grade is too high.
---

# Prose Polish

Applies Hemingway-style sentence-level fixes to markdown documents. Targets clarity and reading ease - not macro structure (use the `blogpost` skill for that).

## What this skill fixes

### Sentence readability (red/yellow)

Two formulas combine to grade sentences. Flesch Reading Ease (FRE) maps to grade level:

```text
FRE  = 206.835 − 1.015 × (words/sentences) − 84.6 × (syllables/words)
FKGL = 0.39 × (words/sentences) + 11.8 × (syllables/words) − 15.59
```

Higher FRE = easier. Lower FKGL = easier. They move inversely.

**Hemingway highlight thresholds:**

| Highlight | FKGL | Action |
| --------- | ---- | ------ |
| Red | > 14 | Must fix |
| Yellow | 12-14 | Fix unless technical necessity |
| None | ≤ 10 | Acceptable for general audiences |

**FRE score guide (for context):**

| FRE | Grade | Audience |
| --- | ----- | -------- |
| 90-100 | 5th grade | Very easy, 11-year-olds |
| 80-90 | 6th grade | Easy, conversational |
| 70-80 | 7th grade | Fairly easy |
| 60-70 | 8th-9th grade | Standard - target for most writing |
| 50-60 | 10th-12th grade | Fairly difficult |
| 30-50 | College | Difficult |
| 10-30 | College graduate | Very difficult |
| 0-10 | Professional | Extremely difficult |

**Audience targets:**

| Audience | FKGL target | FRE target |
| -------- | ----------- | ---------- |
| ESL / young readers | ≤ 4 | > 80 |
| Broad / general | ≤ 8 | > 60 |
| Average US adult | ≤ 9 | ≥ 60 |
| Technical / specialized | ≤ 12 | ≥ 50 |

**How to fix:** Split at "and/but/because/which/that", remove subordinate clauses, convert compound sentences to two sentences.

### Passive voice (blue)

Pattern: form of "to be" + past participle.

- "was written by" → "X wrote"
- "is being processed" → "processes"
- "has been deprecated" → deprecated (or: "we deprecated")

Exception: passive is acceptable when the actor is genuinely unknown or irrelevant.

### Adverbs (blue)

`-ly` adverbs modifying verbs weaken the verb. Replace with a stronger verb or cut.

- "runs quickly" → "sprints" or "runs fast"
- "clearly explains" → "explains"
- "simply calls" → "calls"

Cut list: very, really, quite, just, basically, actually, simply, certainly, definitely, extremely, fairly, mostly, rather, somewhat.

### Qualifiers (blue)

Words that hedge without adding meaning. Cut them.

Cut list: a bit, a little, kind of, sort of, I think, I believe, maybe, perhaps (unless genuine uncertainty), seems to, appears to.

### Complex words with simple alternatives (purple)

| Complex | Simple |
| --------- | -------- |
| utilize | use |
| commence | start |
| approximately | about |
| demonstrate | show |
| facilitate | help |
| implement | build / add / do |
| leverage | use |
| obtain | get |
| require | need |
| sufficient | enough |
| terminate | end / stop |
| numerous | many |
| additional | more |
| subsequently | then / next |
| prior to | before |
| in order to | to |
| due to the fact that | because |
| at this point in time | now |
| in the event that | if |

### Sentence length

Hard limit: 35 words per sentence for general audiences. Sentences over 25 words deserve scrutiny.

### Filler transitions

Cut or replace: "So,", "Now,", "Of course,", "Obviously,", "It's worth noting that", "It should be noted that", "As mentioned", "As we can see".

## Workflow

1. Read the full document.
2. Work sentence by sentence. For each problem, apply the fix directly.
3. Preserve the author's voice - restructure, don't rewrite for its own sake.
4. After edits, run markdownlint:

```sh
npx markdownlint-cli --fix --disable MD013 --ignore node_modules -- <file>
npx markdownlint-cli --disable MD013 --ignore node_modules -- <file>
```

Fix any remaining lint errors by hand.

## Style rules (always apply)

- No em dashes (—). Use ` - ` (space-hyphen-space) instead.
- Short paragraphs. One idea per paragraph.
- Concrete nouns over abstract ones. Name the thing: a tool, a team, a real scenario.

## What this skill does NOT cover

- Macro structure, hook placement, argument arc → use `blogpost`
- Grammar and spelling → use a grammar tool or Hemingway Editor Plus
- Content accuracy, completeness, technical correctness
