# Knowledge Ingestion

Ingest knowledge from any source (Apple Notes, MS Todo, LinkedIn, Reddit, files, URLs, raw text) into the mcp-brain Second Brain vault. Uses one subagent per item to keep the main context lean.

## Core Principle

**Main agent orchestrates. Subagents process. Full item content never accumulates in the main context.**

## Sources & How to Read Them

| Source | MCP Tool to Read | MCP Tool to Delete/Update |
|---|---|---|
| Apple Notes | `mcp__apple-notes__get-note-content` | `mcp__apple-notes__delete-note`, `mcp__apple-notes__update-note` |
| MS Todo | `mcp__ms-todo__list_tasks` (once per list), then process each task | `mcp__ms-todo__delete_task`, `mcp__ms-todo__complete_task` |
| LinkedIn saved posts | `mcp__linkedin__list_saved_posts` | (no delete available) |
| Reddit saved posts | `mcp__reddit__list_saved_posts`, `mcp__reddit__get_post` | (no delete available) |
| Files | `Read` tool | `Edit`/`Write` to strip ingested parts |
| URLs | `WebFetch` | n/a |

## Main Agent Process

```
1. Call mcp__brain__list_tags once → tag_list
2. List all items from the source (titles/IDs only — do not read full content)
3. created_note_titles = []
   deletion_queue = []

4. For each item sequentially:
   a. Fetch the item content
   b. Dispatch a subagent (see Subagent Instructions below)
      passing: item_content, tag_list, created_note_titles
   c. If STATUS: NEEDS_CLARIFICATION
        → ask the user (show QUESTION + CONTEXT)
        → re-dispatch with clarification_answer appended
   d. If STATUS: DONE
        → append NOTES_CREATED to created_note_titles
        → if INGESTION_COVERAGE: full → add item to deletion_queue

5. Present deletion_queue to user in one batch:
   "These items were fully ingested. Which ones should I delete from the source?"
   Delete only confirmed items.

6. Report summary (see Summary Report section)
```

## Subagent Instructions

Use the Agent tool. Pass the following as the prompt, substituting the placeholders:

---

You are ingesting a single item into a Second Brain vault.

MCP tools are available but deferred — call ToolSearch first to load any schema before using it.

**If source is MS Todo:** treat the task body + checklist items as the full item content. Create one note per task (merge only if it's clearly a sub-idea of a note just created). Checklist items are sub-points of that note, not separate notes.

**Item content:**
{{ITEM_CONTENT}}

**Existing tags** (prefer these; only define new ones if nothing fits):
{{TAG_LIST}}

**Notes created this session** (use for wikilinks if clearly relevant):
{{CREATED_NOTE_TITLES}}

{{#if CLARIFICATION_ANSWER}}
**Clarification from user:** {{CLARIFICATION_ANSWER}}
{{/if}}

### Decision

Classify this item as one of:

- **SKIP** — personal todos unrelated to any project, empty/trivial content, contacts, pure shopping lists
- **INGEST** — tech notes, ideas, observations, reference material, career/leadership insights, political/societal thoughts, work context, project specs, story/book ideas (including adult content)
- **NEEDS_CLARIFICATION** — brief items (1–5 lines) mentioning a recognizable project, client, employer, technology, or work context where the purpose is genuinely unclear

If a CLARIFICATION_ANSWER is present, use it to resolve any prior NEEDS_CLARIFICATION — do not return NEEDS_CLARIFICATION again.

### Actions

**If SKIP:**
```
STATUS: DONE
NOTES_CREATED: []
INGESTION_COVERAGE: full
```

**If NEEDS_CLARIFICATION (no clarification answer provided):**
```
STATUS: NEEDS_CLARIFICATION
QUESTION: <what to ask the user>
CONTEXT: <relevant excerpt from the item>
```

**If INGEST:**
1. Pick 1 PARA tag + 1–2 topic tags from the tag list
2. Call `mcp__brain__create_note`
3. Add `[[Title]]` wikilinks to notes in CREATED_NOTE_TITLES where clearly relevant — do not guess titles
4. Assess: did you capture ALL meaningful content (full) or only part (partial)?
5. Return:
```
STATUS: DONE
NOTES_CREATED: [list of created note titles]
INGESTION_COVERAGE: full | partial
```

### Tags
PARA: `resource`, `project`, `area`, `archive`
Topic: `tech`, `ai`, `aws`, `leadership`, `career`, `politics`, `productivity`, `ideas`, `personal`, `writing`

---

## Summary Report

After all items and deletions are handled, report:
- Notes ingested (count + titles)
- Items skipped (brief reason: trivial, personal, unclear)
- Items partially ingested (user may want to review originals manually)
- Deletions performed
