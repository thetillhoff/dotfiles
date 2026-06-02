# Knowledge Ingestion

Ingest knowledge from any source into the mcp-brain Second Brain vault. Uses subagents for parallel composition, then sequential review with dedup checks.

Example sources: note-taking apps (Apple Notes, Notion, etc.), todo apps (MS Todo, Todoist, etc.), local files, URLs, saved posts from social platforms. The user will tell you what to ingest and where to read from at runtime.

## Core Principle

**Main agent orchestrates. Subagents compose. Full item content never accumulates in the main context.**

**Review before submit.** Subagents compose notes but never save them. The main agent reviews all composed notes sequentially for user approval, deduplication, and cross-item linking before saving.

## Sources

Use whatever MCP tools or built-in tools (Read, WebFetch) are available to access the source the user specifies. Use ToolSearch to discover available MCP tools at runtime. If the required MCP server isn't connected, ask the user to install/connect it.

## Main Agent Process

```
1. Call mcp__brain__list_tags once → tag_list
2. List all items from the source (titles/IDs only — do not read full content)
3. created_note_titles = []
   deletion_queue = []
   embedding_failures = false

4. Call ToolSearch "select:mcp__brain__create_note,mcp__brain__define_tag,mcp__brain__get_embedding,mcp__brain__find_similar" once → load schemas

--- COMPOSE PHASE (parallel) ---

5. Fetch all item contents in parallel (or batched if source requires)
6. Dispatch one subagent per item in parallel (see Subagent Instructions below)
   passing: item_content, tag_list (initial snapshot)
   Collect results: array of { item_id, status, notes[], new_tags[], ingestion_coverage }

7. Collect all NEEDS_CLARIFICATION items. Present them to the user in one batch:
   show QUESTION + CONTEXT for each. Re-dispatch those items with clarification_answer.

--- REVIEW PHASE (sequential) ---

8. For each composed result (in order):
   a. If STATUS: SKIP → continue
   b. If STATUS: REVIEW_PENDING (one or more note blocks):
      For each note block sequentially:
        i.  DEDUP CHECK: call mcp__brain__get_embedding with the note title + content,
            then call mcp__brain__find_similar with the returned vector (limit 3).
            If the closest match exists (any distance — always show it):
              Show the user: "Closest existing note: [[Title]] (distance: X.XX)"
              Let them decide: "Save anyway / Skip / Merge into existing"
        ii. CROSS-ITEM LINKING: check if any title in created_note_titles is clearly
            related — if so, add [[wikilinks]] or suggest links.
        iii. TAG DEDUP: if any proposed NEW_TAG is semantically similar to an existing
             tag (check via mcp__brain__find_similar_tags or manual comparison), suggest
             using the existing tag instead.
        iv. Render the note as formatted markdown (see Review Display below)
            - if NEW_TAGS present: show them inline as "New tags: name — description"
        v.  Ask: "Save this note? (yes / no / <edit instructions>)"
        vi. If yes:
              * call mcp__brain__create_note with tags and new_tags
              * add title to created_note_titles
              * merge new tags into tag_list
              * if create_note response has embedding_status: "pending":
                embedding_failures = true
        vii. If no: skip this note
        viii. If edit instructions: apply edits, show updated version, ask again
   c. After all blocks for an item: use INGESTION_COVERAGE to decide deletion_queue

9. Present deletion_queue to user in one batch:
   "These items were fully ingested. Which ones should I delete from the source?"
   Delete only confirmed items.

10. If embedding_failures = true:
    Call mcp__brain__resync to recover any notes that failed to embed during ingestion.

11. Report summary (see Summary Report section)
```

## Subagent Instructions

Use the Agent tool. Pass the following as the prompt, substituting the placeholders:

---

You are ingesting a single item into a Second Brain vault.

MCP tools are available but deferred — call ToolSearch first to load any schema before using it.

**If source is a todo/task app:** treat the task body + checklist items as the full item content. Create one note per task (merge only if it's clearly a sub-idea of a note just created). Checklist items are sub-points of that note, not separate notes.

**Item content:**
{{ITEM_CONTENT}}

**Existing tags** (prefer these; only define new ones if nothing fits):
{{TAG_LIST}}

### Decision

Classify this item as one of:

- **SKIP** — personal todos unrelated to any project, empty/trivial content, contacts, pure shopping lists
- **INGEST** — tech notes, ideas, observations, reference material, career/leadership insights, political/societal thoughts, work context, project specs, story/book ideas (including adult content)
- **NEEDS_CLARIFICATION** — brief items (1–5 lines) mentioning a recognizable project, client, employer, technology, or work context where the purpose is genuinely unclear

### Actions

**If SKIP:**
```
STATUS: DONE
NOTES_CREATED: []
INGESTION_COVERAGE: full
```

**If NEEDS_CLARIFICATION:**
```
STATUS: NEEDS_CLARIFICATION
QUESTION: <what to ask the user>
CONTEXT: <relevant excerpt from the item>
```

**If INGEST:**
1. Check whether the item contains multiple distinct sections (visual separators, topic shifts, or structural markers of any kind):
   - **Clearly distinct topics** → split into one note per section (see multi-note format below)
   - **Sections present but relationship ambiguous** → return NEEDS_CLARIFICATION instead:
     ```
     STATUS: NEEDS_CLARIFICATION
     QUESTION: This note appears to contain multiple sections. Are these distinct topics to split into separate notes, or related content for one note?
     CONTEXT: <brief description of each section>
     ```
   - **Single coherent topic** → one note
2. For each note: pick 1 PARA tag + 1–2 topic tags from the tag list
3. Compose the note body — do NOT call `mcp__brain__create_note`
   - Write the full markdown body, structured clearly with headings where useful
4. Assess: did you capture ALL meaningful content from the source item (full) or only part (partial)?
5. Return one block per note. Repeat the block for each note; only the last block includes INGESTION_COVERAGE:
```
STATUS: REVIEW_PENDING
NOTE_TITLE: <title>
NOTE_TAGS: [tag1, tag2]
NOTE_LINKS: [{"target": "Title", "type": "related"}]  # omit if none
NOTE_CONTENT:
<full markdown body here>

STATUS: REVIEW_PENDING
NOTE_TITLE: <title of second note>
NOTE_TAGS: [tag1, tag2]
NOTE_CONTENT:
<full markdown body here>
INGESTION_COVERAGE: full | partial
```

### Tags

Use tags from the **Existing tags** list above. If no existing tag fits a major theme of the item, include the new tag name directly in NOTE_TAGS and declare it in a NEW_TAGS block with a description:

```
NEW_TAGS:
- name: <kebab-case>
  description: <one-line description of what this tag covers>
```

---

## Review Display

When rendering a REVIEW_PENDING note for the user, format it as:

~~~
---
title: <NOTE_TITLE>
tags: [tag1, tag2]
links:
  - target: Linked Note Title
    type: related
---

<NOTE_CONTENT>
~~~

If NEW_TAGS are present, show them below the frontmatter block:
> **New tags:** `machine-learning` — Machine learning notes; `llm` — Large language model topics

Show the source item title above so the user knows what's being ingested. Ask for approval on one line after the block: `Save this note? (yes / no / edit instructions)`

If the user provides edit instructions, apply them inline, re-render the updated note, and ask again — do not re-dispatch the subagent.

## Summary Report

After all items and deletions are handled, report:
- Notes ingested (count + titles)
- New tags created (name + description)
- Items skipped (brief reason: trivial, personal, unclear)
- Items partially ingested (user may want to review originals manually)
- Deletions performed
