# Knowledge Ingestion

Ingest knowledge from any source into the mcp-brain Second Brain vault. Uses one subagent per item to keep the main context lean.

Example sources: note-taking apps (Apple Notes, Notion, etc.), todo apps (MS Todo, Todoist, etc.), local files, URLs, saved posts from social platforms. The user will tell you what to ingest and where to read from at runtime.

## Core Principle

**Main agent orchestrates. Subagents process. Full item content never accumulates in the main context.**

**Review before submit.** Subagents compose notes but never save them. The main agent shows each note as formatted markdown for user approval, then saves it. This keeps the user in control of what enters the vault.

## Sources

Use whatever MCP tools or built-in tools (Read, WebFetch) are available to access the source the user specifies. Use ToolSearch to discover available MCP tools at runtime. If the required MCP server isn't connected, ask the user to install/connect it.

## Main Agent Process

```
1. Call mcp__brain__list_tags once → tag_list
2. List all items from the source (titles/IDs only — do not read full content)
3. created_note_titles = []
   deletion_queue = []

4. Call ToolSearch "select:mcp__brain__create_note" once → load schema for later use

5. For each item sequentially:
   a. Fetch the item content
   b. Dispatch a subagent (see Subagent Instructions below)
      passing: item_content, tag_list, created_note_titles
   c. If STATUS: NEEDS_CLARIFICATION
        → ask the user (show QUESTION + CONTEXT)
        → re-dispatch with clarification_answer appended
   d. If STATUS: REVIEW_PENDING (one or more blocks)
        → if NEW_TAGS present:
           - show proposed tags to user: "Subagent suggests new tags: <name> — <description>. Define them?"
           - if approved: call mcp__brain__define_tag for each, add to tag_list
           - if rejected: remove those tags from NOTE_TAGS, substitute closest existing tag
        → for each note block sequentially:
           - render as formatted markdown (see Review Display below)
           - ask: "Save this note? (yes / no / <edit instructions>)"
           - if yes: call mcp__brain__create_note, add title to created_note_titles
           - if no: skip this note
           - if edit instructions: apply edits, show updated version, ask again
        → after all blocks: use INGESTION_COVERAGE from the last block to decide deletion_queue
   e. If STATUS: DONE
        → append NOTES_CREATED to created_note_titles
        → if INGESTION_COVERAGE: full → add item to deletion_queue

6. Present deletion_queue to user in one batch:
   "These items were fully ingested. Which ones should I delete from the source?"
   Delete only confirmed items.

7. Report summary (see Summary Report section)
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
   - Add `[[Title]]` wikilinks to notes in CREATED_NOTE_TITLES where clearly relevant — do not guess titles
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

Use tags from the **Existing tags** list above. If no existing tag fits a major theme of the item, propose a new tag:
- Append a `NEW_TAGS` block with name + description for each proposed tag
- The main agent will ask the user for approval and call `mcp__brain__define_tag` before saving

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

Show the source item title above so the user knows what's being ingested. Ask for approval on one line after the block: `Save this note? (yes / no / edit instructions)`

If the user provides edit instructions, apply them inline, re-render the updated note, and ask again — do not re-dispatch the subagent.

## Summary Report

After all items and deletions are handled, report:
- Notes ingested (count + titles)
- Items skipped (brief reason: trivial, personal, unclear)
- Items partially ingested (user may want to review originals manually)
- Deletions performed
