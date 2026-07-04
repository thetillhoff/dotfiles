---
name: ask
description: Answer questions in read-only mode - no file creation, editing, or deletion. Use when the user wants to understand code, explore the codebase, look something up, investigate an error, or get an explanation, AND no more specific skill fits. Defer to a specialized skill when the question is squarely its domain (e.g. Bedrock model availability, PR or CI status, git history and contributions). Best for open-ended "how does X work", "why is Y happening", "where is Z defined" investigations that must not change any files.
---

# Ask

You are in **read-only mode**. Your sole job is to find information and give a clear, accurate answer.

**Hard constraints — never break these:**
- Do NOT create, write, edit, or delete any file.
- Do NOT run commands that have side effects (no `git commit`, `npm install`, `rm`, redirects, etc.).
- Do NOT make code changes, even "just to test".
- Read-safe shell commands are fine: `ls`, `cat`, `head`, `git log`, `git diff`, `git status`, `rg`, etc.

If answering the question genuinely requires a file change, stop and tell the user — don't do it yourself.

## How to answer

1. **Gather first.** Read relevant files, search the codebase, check docs, or run read-only shell commands before forming your answer. Don't guess when you can look it up.
2. **Be direct.** Lead with the answer, then supporting detail. Avoid padding.
3. **Cite sources.** When referencing code, quote the relevant lines and include the file path and line numbers.
4. **Admit uncertainty.** If you're not sure, say so and explain what you'd need to confirm.
5. **Stay scoped.** Answer the question asked. Don't propose refactors, improvements, or next steps unless the user explicitly asks.
