---
name: rewrite-git-history
description: Use when text (a name, an address, a secret, personal data) must leave the git history of a repo, not only the latest commit. Triggers - "remove it from the git history", "scrub the history", "change the history so X is not visible", "it must not appear in git log -S". This host has no `git filter-branch` and no `git-filter-repo`, and the auto-mode check refuses a history rewrite. The skill builds the new branch itself and gives the destructive commands to the user.
---

# Rewrite git history

The script `scrub-history.sh` replays the commits with `git commit-tree`. Author, dates and messages stay. Only the text of chosen files changes. It moves no branch and deletes nothing, so it is safe to run.

## 1. Find

- `git log --all -S'<text>' -i --format='%h %ad %s'` for each text. Add `git grep -I -i '<text>'` for the tree, and `git log --all --grep=<text> -i` for commit messages.
- A name is rarely alone. Read the file that holds it (a capture, a fixture) and list every identifying line: website, phone, mail, ID codes.
- `git branch -a --contains <sha>` shows what is already on the remote. `gh repo view <owner>/<repo> --json visibility,forkCount` shows who can see it.
- Binary files can match by chance (a PDF). `-I` skips them.

## 2. Decide with the user

- Per text: the replacement (invented, same length), and the files. A legitimate use stays: the company address in `company.js` is no secret. Restrict each rule to the files that hold the old text, and say what stays.
- Fix the tip first: commit the clean state at HEAD. Then the tip of the new branch equals HEAD, and the check passes.

## 3. Build

1. One sed script per file (`s/old/new/`). A rules file with one line per file: `path<TAB>sedfile`.
2. `PATTERN='old1|old2' sh <skill-dir>/scrub-history.sh '<first-rewritten-commit>^' rules.txt`
3. The script prints three checks: author, dates and subjects are identical; the tip equals the current branch; no rewritten commit matches `PATTERN`. A false match (a comment that names the text) needs one more rule: fix the tip, run again.
4. A merge commit in the range stops the script. Rewrite a linear range.

## 4. Hand over

Never run the destructive commands: the auto-mode check refuses them, and the user chose to run them. Give them as a block, with the branch names filled in:

```sh
git reset --soft <branch>-scrubbed     # moves the checked-out branch; `git branch -f` refuses that
git status                             # must be clean, the content is equal
git push --force-with-lease origin <branch>
git branch -D <branch>-scrubbed
git reflog expire --expire=now --all
git gc --prune=now
```

Say what the push changes: only the rewritten branch, new hashes from the first rewritten commit on. Another branch that holds the old text needs the same treatment. GitHub keeps old hashes reachable for a while: only GitHub support removes them.

## 5. Check after

Read-only, after the user says it is done:

- `git branch -a`, `git rev-parse <branch> origin/<branch>` (equal), `git status -sb` (clean).
- The old text in every commit of every ref: `for n in $(git rev-list --all); do git grep -q -I -E "$PATTERN" $n -- && echo $n; done`
- `git rev-list --count <branch>` (old count plus new commits), `main` unchanged, no stash. The old objects are gone after the `gc`: a comparison with the old history is no longer possible, so do the metadata check before.
