---
name: cli-naming
description: >
  Generate and rank short CLI tool names. Use whenever the user is naming a CLI tool, terminal app, developer utility, or any command-line project and wants name suggestions. Triggers on: "name this tool", "what should I call it", "suggest a name", "help me name", naming a CLI/terminal/dev tool, or when a user describes a project and asks for name ideas. Also triggers when the user is unhappy with current name suggestions and wants more.
---

# CLI Naming

Generate a **shortlist of 5-8 ranked candidates**. No exhaustive lists. Score each on four dimensions, then rank.

## Scoring Dimensions

### 1. Keyboard ergonomics (QWERTY)

Finger assignments (standard touch typing):
```
Left pinky:  Q A Z
Left ring:   W S X
Left middle: E D C
Left index:  R F V T G B   ← index covers two columns
Right index: Y H N U J M
Right middle: I K
Right ring:  O L
Right pinky: P ; /
```

Score in order of importance:
1. **Same finger**: consecutive letters typed by same finger — worst, causes stumble (e.g. f→t both left index, u→n both right index)
2. **Same hand**: consecutive same-hand letters — adds friction but ok if rolling (adjacent fingers moving inward)
3. **Alternating hands**: best — every switch is a rest

Always call out specific collisions explicitly (e.g. "u→n same finger", "t→b left index stretch"). These micro-warnings are the most useful part of the analysis — they surface friction the user can feel but might not notice consciously until typing the name a hundred times.

Penalize hard-reach keys: T B Y X — all require the index finger to stretch far from home row. A name heavy in these is tiring to type repeatedly.

Also reward: home-row letters (A S D F J K L), common starting letters.

### 2. Length

- 2–3 chars: terse/punchy (good if memorable, risky if too cryptic)
- 4 chars: sweet spot
- 5 chars: acceptable
- 6+: justify it

### 3. Semantic fit

Does the word's meaning (or feel) reflect what the tool does?
- Direct metaphor: best
- Evocative/adjacent: good
- Arbitrary but distinctive: ok
- Misleading or generic: bad

Words from Latin/Italian/Old English can work if the root meaning fits and the word is short.

### 4. Conflict check

Flag if the name is:
- A shell builtin (`test`, `read`, `type`, `kill`, `jobs`, etc.)
- A major package manager or runtime (`npm`, `pip`, `nvm`, `brew`, `cargo`)
- A well-known dev tool or brand (`flux`, `helm`, `node`, `code`, `vim`, `curl`)
- An active product brand in adjacent space (check your training data; note uncertainty)

If conflicted: mark it, don't drop it unless the conflict is severe (shell builtin = drop).

## Output Format

For each candidate:

```
**name** — one-sentence meaning/etymology
Keyboard: [pattern rating + quick note]
Length: [N chars]
Semantic: [how it fits]
Conflicts: [none / weak / strong: name what conflicts]
```

Then a **Recommendation** block: pick the top 1-2 and say why in 2 sentences max.

## What NOT to do

- Don't generate 20 names. Pick the best 5-8.
- Don't explain the scoring system to the user — just use it.
- Don't recommend a name with a shell builtin conflict.
- Don't pad with generic words (`flow`, `run`, `exec`, `go`) unless they score exceptionally well on the other dimensions.

## Example

User: "Naming a CLI tool that routes requests to different AI models based on complexity."

Good candidates: `sift` (filters signal), `wren` (fast, small, L-R-L-R), `cue` (signals/prompts), `kern` (core routing logic), `pike` (sharp/direct).

Bad candidates to skip: `router` (too long, generic), `flux` (Kubernetes brand), `type` (shell builtin).
