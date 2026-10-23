---
name: close
description: >
  The last step of a session before the user closes it or runs /clear. Derive the
  session's reusable learnings and write each one into the one file where the next
  agent will read it: global or repo CLAUDE.md/AGENTS.md, a global or repo skill,
  README, TODO.md, KNOWN-ISSUES.md. Edit, merge or delete existing entries. Never
  just append. Also close the open threads of the session: unanswered questions,
  uncommitted or unpushed work, open branches. Use on "/close", "wrap up", "anything to save?", "before I clear".
---

# Close

Goal: the next session works better with the user than this one did. Every write must change what a future agent does. Text that changes nothing is bloat. Do not write it.

## 1. Close open threads

Do this before you collect learnings. A session ends only when no thread is open.

1. **History:** read the session for open topics: a question the user asked and you did not answer, a decision that waits for the user, a step you announced and did not do, a gap you noted and did not record.
2. **Repos:** for each repo touched in the session (also the repo of a file you wrote outside the working directory), `cd <repo> && git status --short`, `git branch --show-current`, `git branch -vv` and `git log @{u}..` (unpushed commits). Do not rely on the status snapshot from the session start.
3. **Branches:** list local branches that are not merged into the default branch of the repo, and branches that are ahead of their upstream or have none.
4. **Sort each finding:**
   - **Finish it now:** a coherent uncommitted change. Verify it, then commit it with a written message. Never stage a change that you did not make: add paths, never `git add -A`.
   - **Needs the user:** an unmerged branch, a decision, an unanswered question. Merge and delete only on request. Name each one.
   - **Unpushed commits:** mention the count in one clause. Do not ask to push. Do not give the command or explain how to push. The user knows.
   - **Record it:** a deferred item goes to `TODO.md` (routing: step 3), so no thread lives only in chat.
5. **Ask:** put every "needs the user" item and every skill proposal (step 3) in one list, with the answer that closes it. Stop and wait for the answer before you report. Do not end the session with an open thread.
   - **Each item stands alone.** The user may read it hours later, or only this list. Give the full context: what the thing is, where it lives (page, file, command), what state it is in, what the options are, and your recommendation. Never write "the earlier question", "as discussed" or "the item above". A reader who saw nothing else must be able to answer.

## 2. Collect candidates

Read the whole session, the summary included. List only these:

- **Corrections:** the user said "no", "not like that", or redid your work. Find the rule behind the correction, not the single fix.
- **Confirmed choices:** the user chose between options, or accepted an unusual approach. Record the choice and its reason.
- **Traps:** a tool, a host or an API failed in a way that cost more than one attempt. Record the symptom and the fix.
- **Stale guidance:** a file or skill gave a wrong, incomplete or outdated instruction. Fix it in place.
- **Open state:** unfinished work, deferred decisions, accepted gaps.
- **Skill gaps:** a procedure that the session did by hand in 3 or more steps and that a future session will repeat, with no skill that covers it. Also a skill that the session used and that needed workarounds, missed a case or loaded too much.

Drop a candidate when one of these is true:

- The code, a name, `git log` or a tool's own output already shows it.
- It mattered only for this task.
- A file already states it. Then check that the wording was clear enough. If an agent broke the rule anyway, make the rule sharper.
- It is a public standard or a well-known practice. Name it, do not explain it.

## 3. Route each survivor

Pick exactly one destination. Use the narrowest scope that is still always loaded when the learning applies.

| Learning | Destination |
| --- | --- |
| Cross-repo preference, workflow rule, host quirk | global `~/.claude/CLAUDE.md` (and `AGENTS.md` if one exists there) |
| Fact or rule of one repo | that repo's `CLAUDE.md` / `AGENTS.md` |
| Procedure with steps, used only in some tasks, cross-repo | global skill `~/.claude/skills/<name>/` |
| The same, for one repo | `<repo>/.claude/skills/<name>/` |
| Something a human user of the repo needs | `README.md` or the relevant doc |
| Work someone will do | `TODO.md` (follow the `todo-md` skill) |
| Accepted gap, no fix planned | `KNOWN-ISSUES.md` |
| Correction or improvement of an existing skill | that skill, in place |

A new skill is a proposal. Do not create it. Before you propose, list the skills and check that no existing skill covers the procedure: extend that one instead. Put each proposal in the step 1 question list: name, one-line trigger, scope (global or repo), and the steps it would hold. Create the skill (use `skill-creator`) only after an explicit yes.

An improvement of an existing skill is direct when it is a small fix of a wrong or missing line. A larger change is a proposal too: a new section, a rewrite, a split or a merge. Name the skill and the change in the question list.

Do not write project facts into `~/.claude/projects/*/memory/`.

## 4. Write

- First, search the destination for the topic (`grep`). Extend, sharpen, merge or delete the existing entry. Add a new entry only when no entry covers the topic.
- One entry is one rule. The imperative comes first. Add the reason in one clause when the rule is not obvious. Add the concrete symptom when it is a trap, so a future agent recognises it.
- Delete or rewrite what the session proved wrong. A stale entry is worse than none.
- Follow the destination's existing structure and the prose rules of the global CLAUDE.md (STE, no em dashes).
- Lint each markdown file you changed. Commit the repo files: one commit, `docs:` type. Do not commit files outside a repo.

## 5. Report

Start with the threads: what you closed, and what still waits for the user. Then give a table with three columns: destination, change, reason. Use one line per change. Then list the candidates that you dropped, with the reason for each in a few words. If nothing survives, say "Nothing to save" and give the reason.
