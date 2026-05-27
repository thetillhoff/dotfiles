---
name: pr-comments
description: Retrieve and display PR review comments, pipeline/check status, and failures for the current branch. Use when the user asks to check PR comments, review feedback, see what reviewers said, check CI status, fix failing checks, or wants to address PR review comments. Also use when the user says "check the PR", "what did reviewers say", "any comments on the PR", "retrieve PR feedback", "fix the pipeline", or "why is CI failing".
---

# PR Comments & Checks

Retrieve and display review comments, general comments, and CI/check status for the pull request associated with the current branch.

## Steps

1. **Get the current branch name:**

   ```bash
   git branch --show-current
   ```

2. **Find the PR number for this branch:**

   ```bash
   gh pr list --head <branch-name> --json number,url
   ```

   If no PR exists, tell the user and stop.

3. **Fetch review comments** (inline comments on code):

   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | "---\n**\(.user.login)** on `\(.path)` (line \(.original_line // .line // "N/A")):\n\(.body)\n"'
   ```

4. **Fetch issue comments** (general PR conversation):

   ```bash
   gh api repos/{owner}/{repo}/issues/{number}/comments --jq '.[] | "---\n**\(.user.login)** (general comment):\n\(.body)\n"'
   ```

5. **Check CI/pipeline status:**

   ```bash
   gh pr checks
   ```

   For any failing checks, fetch logs to understand the failure:

   ```bash
   gh run view <run-id> --log-failed
   ```

   Extract the run ID from the check's details URL (the numeric segment in `/runs/<id>/`).

6. **Present results** to the user:
   - Review comments first, then general comments
   - Then CI status: list failing checks with a brief summary of the failure cause
   - If either category is empty, note that

## Deriving owner/repo

Extract from the git remote:

```bash
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

This gives `owner/repo` directly.

## After displaying

Summarize actionable items — which comments suggest changes, which are informational, which CI checks need fixing. For CI failures, suggest the fix (e.g., "run `./do format`" for stylecheck failures). Ask the user if they want to address any of them.
