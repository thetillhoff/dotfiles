---
name: review-comments
description: >
  Reviews code comments and inline documentation in changed files for quality and correctness.
  Use this skill whenever the user asks to review, audit, or clean up comments, docstrings, or
  inline documentation — or when finishing a PR and checking code quality.
  Flags: comments that describe WHAT instead of WHY; comments that describe history or process
  rather than current state; comments that restate what well-named identifiers already say;
  doc comments on exported symbols that are inaccurate, incomplete, or missing; and comments
  that are longer than necessary. Returns file/line, the violation, and a concrete replacement.
---

## What to check

For each comment in the changed files, verify:

1. **WHY not WHAT** — The comment explains a non-obvious reason, constraint, or invariant. If removing the comment wouldn't confuse a future reader who can see the code, it shouldn't exist.

2. **Current state, not history** — No references to what the code used to do, what was added/changed/fixed, which PR/issue it came from, or what the caller is. That belongs in commit messages and PR descriptions, not source code.

3. **Not restating names** — A comment like `// increments counter` above `counter++` or `// Store the user` above `store.Put(user)` adds no information the code doesn't already convey.

4. **Concise** — Single line unless the WHY genuinely requires more. Multi-line blocks are almost always a sign the comment is doing too much.

5. **Exported symbol doc comments** — In Go: every exported type, function, method, and const should have a doc comment starting with the symbol name. Check that it's accurate (matches the actual behaviour) and complete (covers non-obvious parameters, return values, or error conditions).

## What NOT to flag

- License headers
- TODO/FIXME with a reason (though flag ones with no reason)
- Section dividers in large files where they genuinely aid navigation
- Test helper comments that orient the reader ("// First REGISTER without credentials — expect 401")

## Output format

For each violation, output:

```
file:line
  VIOLATION: <one-sentence description of the problem>
  CURRENT:   <the existing comment>
  SUGGESTED: <replacement, or "remove" if it should be deleted>
```

Group by file. If a file has no violations, skip it. If there are no violations at all, say so plainly.

## Scope

Default scope is the current diff (`git diff @{upstream}...HEAD`). If the user passes a file path or PR number, scope to that instead.
