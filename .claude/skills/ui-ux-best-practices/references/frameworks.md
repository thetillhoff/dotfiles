# Canonical UX/Design Frameworks

Lookup reference for the named theory behind the SKILL.md checklist. Cite these
by name when justifying a decision or running a heuristic evaluation.

## Nielsen's 10 Usability Heuristics (NN/g)

Rules of thumb for evaluating any interface. Walk them as an audit checklist.

1. **Visibility of system status** - always show what is going on, with timely feedback.
2. **Match between system and real world** - speak the user's language; follow real-world conventions, not internal jargon.
3. **User control & freedom** - clear exits, undo, and redo; let users escape mistakes.
4. **Consistency & standards** - same word/action means the same thing; follow platform conventions.
5. **Error prevention** - design out the error before you need an error message.
6. **Recognition rather than recall** - show options; don't make users remember things across screens.
7. **Flexibility & efficiency of use** - shortcuts and accelerators for experts, hidden from novices.
8. **Aesthetic & minimalist design** - only what is relevant; every extra element competes with the essentials.
9. **Help users recognize, diagnose, recover from errors** - plain-language messages that state the problem and suggest a fix.
10. **Help & documentation** - searchable, task-focused, available in context when needed.

## Tog's First Principles of Interaction Design (Bruce Tognazzini)

Higher-level principles that complement the heuristics.

- **Aesthetics** - visual quality without sacrificing usability.
- **Anticipation** - bring the tools and info the user will need to them; don't make them hunt.
- **Autonomy** - give users control within safe boundaries.
- **Color** - use it, but always provide a non-color cue for colorblind users.
- **Consistency** - user expectations outrank internal logic; match what people already know.
- **Defaults** - intelligent, clearly labeled, and replaceable.
- **Discoverability** - keep needed controls visible; false simplicity by hiding is a trap.
- **Efficiency of the user** - optimize for human productivity, not machine cycles.
- **Explorable interfaces** - reversible actions and clear exits so users can explore safely.
- **Fitts's Law** - acquisition time grows with distance and shrinks with target size; make important targets big and near.
- **Human-interface objects** - objects users can see, manipulate with standard methods, and predict.
- **Latency reduction** - acknowledge within ~50ms; mask delays; keep users informed during waits.
- **Learnability** - balance ease of learning against long-term efficiency by how often it's used.
- **Metaphors** - choose ones that communicate capability and adapt to new functions.
- **Protect users' work** - never lose their data, whatever fails.
- **Readability** - high contrast, large enough text, data over labels; test with older eyes.
- **Simplicity** - manage complexity via progressive revelation; don't just hide it.
- **State** - remember where the user is and what they've done across sessions.
- **Visible navigation** - explicit, consistent, current-location highlighted.

## Gestalt Principles (how the eye groups things)

The perceptual laws behind hierarchy, grouping, and layout.

- **Proximity** - elements placed close together are seen as related.
- **Similarity** - shared shape/color/size makes elements read as a group.
- **Continuity** - items along a line or curve are perceived as connected.
- **Closure** - the mind completes incomplete shapes.
- **Figure-ground** - we separate a foreground figure from its background.
- **Prägnanz (simplicity)** - the brain resolves ambiguity toward the simplest interpretation.
- **Symmetry** - balanced, orderly arrangements feel resolved and are preferred.
- **Connectedness** - a visible connector (line) links elements more strongly than proximity alone.
- **Common region** - a shared enclosure (a card/box) groups its contents.
- **Focal point** - a distinct element captures attention; use it to steer the eye.
- **Common fate** - elements moving together are perceived as a unit.

## Graphic Design Elements & Principles

**Elements** (the raw material): line, shape, color, texture, space, typography.

**Principles** (how you arrange them):

- **Visual hierarchy** - order elements so the eye prioritizes correctly.
- **Contrast** - difference creates emphasis and interest.
- **Balance** - distribute visual weight (symmetrical = formal/stable; asymmetrical = dynamic).
- **Alignment** - shared edges/axes create structure and polish.
- **Proximity** - grouping communicates relationship.
- **Harmony** - shared traits make elements feel like one system.

## Color Schemes

Build a palette from one of these relationships, not ad hoc:

- **Monochromatic** - one hue, varied lightness/saturation. Calm, cohesive.
- **Analogous** - adjacent hues. Comfortable, low-tension.
- **Complementary** - opposite hues. High contrast, strong emphasis.
- **Split-complementary** - a hue plus the two neighbors of its complement. Contrast with less tension.
- **Triadic** - three evenly spaced hues. Vibrant, balanced.
- **Tetradic** - two complementary pairs. Rich but hard to balance; let one hue dominate.

## Design Systems (Figma "Design Systems 101")

A design system is the single source of truth for how a product looks and
behaves - a shared language that keeps experiences consistent and speeds up
building.

**Three layers:**

1. **Foundations** - color, typography, spacing, icons, logo, illustration, and accessibility guidelines (often as design tokens).
2. **Component & pattern libraries** - reusable elements and interaction patterns, with code and documentation.
3. **The system itself** - the overarching standards, principles, and docs tying it together.

**Why it pays off:** consistency across platforms, less redundant work, faster
delivery, easier onboarding, one source of truth. It is a long-term commitment -
budget for ongoing maintenance, not a one-off build.
