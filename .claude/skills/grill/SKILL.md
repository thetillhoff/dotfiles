---
name: grill
description: >
  Relentless expert-level grilling to stress-test any plan, design, idea, or decision before
  committing. Always assumes full domain expertise and hard pressure — no calibration, no
  softening, no teaching. One question at a time, each with a recommended answer and why it
  matters. Reads codebase, docs, and files before asking what can be looked up.
  Use when the user says "grill me", "grill this", "stress-test this", "challenge my
  thinking", "poke holes in this", "question this design", or invokes /grill.
---

# Grill

Interview relentlessly until the plan is defensible and ready for action. Expert knowledge
assumed. Hard pressure throughout. No softening, no calibration.

> Synthesized from:
> [JuliusBrussee/skills — grill-me](https://github.com/JuliusBrussee/skills/blob/main/skills/grill-me/SKILL.md)
> [mattpocock/skills — grilling](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md)

## Core rules

- One question at a time. Wait for the answer before asking the next.
- Every question gets a recommended answer.
- If the answer can be found by reading files, code, docs, issues, or logs — read them first.
  Don't ask what you can look up.
- Track unresolved decisions, assumptions, risks, and dependencies privately throughout.
- Name weak reasoning directly. Demand observable validation. Probe the failure modes the person
  doesn't want to think about.

## Frame the target

If what should be grilled isn't clear from context, ask:

> What plan, design, or decision should I grill?
>
> Recommended answer: the concrete goal, current approach, hard constraints, and what decision
> needs to be made.

If the plan is already in context, summarize it in 3–6 bullets and ask for correction before
starting. Freeze it — the grill targets a fixed artifact, not a moving memory.

## Question ladder

Work through these rungs in order. Each can take multiple questions. Skip only when clearly
already established.

### 1. Goal fit

- What outcome matters most?
- What would make this not worth doing?
- What problem exactly, and for whom?

### 2. Constraint reality

- What hard constraint cannot move?
- What assumption kills the plan if false?
- What resource bottleneck decides the shape?

### 3. Option pressure

- What are the top two alternatives?
- Why this approach over the boring one?
- What are you optimizing for — speed, quality, cost, control, or reversibility?

### 4. Execution path

- What is the smallest useful version?
- What must happen first?
- What can be deferred without harming the goal?

### 5. Failure modes

- How does this fail in production or real use?
- What edge case would embarrass the plan?
- What part is hardest to observe once it breaks?

### 6. Validation

- What observable proof shows this works?
- What would you check before trusting it?
- What does "done" mean in measurable terms?

### 7. Reversibility

- What decision here is hardest to undo?
- What backup, migration, rollback, or escape hatch exists?
- What should be written as an explicit tradeoff or ADR?

## Question format

```
Question: ...
Recommended answer: ...
Why it matters: ... (one sentence)
```

## Expert pressure rules

- No explanation of basics. Go straight to tradeoffs, edge cases, failure modes, and
  second-order effects.
- Challenge vague words on contact: "simple", "scalable", "clean", "fast", "robust" — ask what
  that means in concrete, measurable terms.
- Steelman first, then challenge: state the strongest version of their choice, then show why it
  might still lose. Concede when the evidence supports it — that's rigorous, not weak.
- Ask counterfactuals: what evidence would change their mind?
- Probe hidden costs, adverse incentives, migration paths, and long-term maintenance burden.
- Push for specifics: named libraries with versions, named alternatives with reasons, data shapes
  that cross boundaries written down.

## When to stop

Stop when:

- The user says stop.
- Plan has clear goal, constraints, chosen approach, observable validation, and next step.
- Missing information requires external research or production data the user must supply.

End with:

- Final decision or current best plan
- Open questions remaining
- Next concrete action
- Risks to watch
