---
name: ui-ux-review
description: >
  Wrapper that runs a UI/UX review of the current project with
  ui-ux-best-practices: fix the no-brainers at once, ask about everything else
  with options. Use when the user says "ui-ux review", "review the UI", "review
  the UX", "review this frontend", or "review the design" and wants findings
  fixed or decided, not only listed.
---

# ui-ux-review

Wrapper only. The criteria live in `ui-ux-best-practices`.

## Steps

1. Load `ui-ux-best-practices`. Read the project's own design rules (`CLAUDE.md`, design docs). They override the skill.
2. Review the project's UI against the bold lead-ins of each section.
3. Sort each finding:
   - **No-brainer:** one correct answer, and a lead-in of the skill or a project rule states it. Examples: a missing label, `transition: all`, a bare "Submit" button. Implement it now.
   - **Decision:** layout, wording, hierarchy, or any fix with two valid forms. Do not implement it.
4. Ask about the decisions at once, one question per decision, with 2-3 options that really differ and a recommendation. Use `AskUserQuestion`. Sketch a layout option as a box drawing (section 2 of the skill).
5. Report: the no-brainers applied (file and change), then the answers needed.

Measured gate: for accessibility and viewport findings, run `frontend-verify` and treat its failures as no-brainers.

Do not commit.
