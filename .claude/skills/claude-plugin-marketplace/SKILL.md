---
name: claude-plugin-marketplace
description: Use this skill when contributing a new plugin or skill to a Claude Code plugin marketplace repo (one with a `.claude-plugin/marketplace.json` and `plugins/` directory). Covers scaffolding the directory structure, writing plugin.json and SKILL.md, registering in the marketplace, updating CODEOWNERS and README, and opening a PR. Trigger when the user wants to add a skill to a marketplace repo, package an existing skill as a plugin, or understand how marketplace plugin repos are structured.
user-invocable: true
allowed-tools: Bash(git *) Bash(gh *) Bash(find *) Bash(mkdir *) Read Write Edit
---

# Contributing to a Claude Code Plugin Marketplace

## Repo structure

```
.claude-plugin/
  marketplace.json       — catalog of all plugins
plugins/
  <plugin-name>/
    .claude-plugin/
      plugin.json        — plugin manifest
    skills/
      <skill-name>/
        SKILL.md         — skill definition (auto-discovered)
    agents/              — optional agent .md files (listed in plugin.json)
CODEOWNERS
README.md
```

## Plugin manifest (plugin.json)

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<one-line description>",
  "repository": "https://github.com/<org>/<repo>",
  "keywords": ["3-5 relevant terms"]
}
```

- Never add a `skills` array — skills are auto-discovered from `skills/<name>/SKILL.md`
- Version must be `1.0.0` for new plugins; bump in both `plugin.json` and `marketplace.json` on updates

## Skill frontmatter (SKILL.md)

```yaml
---
name: <skill-name>
description: <one-line, under 1536 chars — front-load the key use case>
user-invocable: true
allowed-tools: <only what the skill needs>
argument-hint: <hint for expected arguments>   # optional
disable-model-invocation: true                  # optional — for side-effectful skills or ones only invoked manually
---
```

Use `${CLAUDE_SKILL_DIR}` to reference files bundled alongside the skill. Keep SKILL.md under 500 lines; move reference material to separate files.

## marketplace.json entry

```json
{
  "name": "<plugin-name>",
  "source": "./plugins/<plugin-name>",
  "description": "<same as plugin.json>",
  "version": "1.0.0",
  "category": "developer-tools",
  "tags": ["same", "as", "keywords"]
}
```

`source` must start with `./`.

## Steps to add a new plugin

1. **Branch** — create a feature branch; never push directly to main
2. **Scaffold** directories as shown above
3. **Write `plugin.json`** using the template above
4. **Write `SKILL.md`** — keep descriptions concise, explain *why* not just *what*
5. **Register** in `.claude-plugin/marketplace.json`
6. **Add CODEOWNERS entry** under `# Plugins`: `/plugins/<name>/ @<handle> @<maintainers-team>`
7. **Update README.md** — add a row to the plugins table: `| \`plugin-name\` | \`skill-name\` | description |`
8. **Commit and PR** — one plugin per PR; verify your GitHub handle with `gh api user --jq '.login'` before writing CODEOWNERS

## Installing from a marketplace

```bash
/plugin marketplace add <org>/<repo>
/plugin install <plugin-name>
```

## Key rules

- One plugin per PR
- Skills with side effects or that should only be manually triggered: add `disable-model-invocation: true`
- Description length matters: it's loaded into context even when the skill isn't active — keep it under 1536 chars
- Prefer `${CLAUDE_SKILL_DIR}` over absolute paths inside skill instructions
