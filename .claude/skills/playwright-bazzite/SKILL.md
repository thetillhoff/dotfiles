---
name: playwright-bazzite
description: >
  Run Playwright on this Bazzite host in Docker only - screenshots, scripted browser
  flows, and the Playwright MCP (`browser_*` tools). Use whenever a task needs a real
  browser: screenshot a URL, click through a local dev server, verify a frontend,
  or when the Playwright MCP or `npx playwright install` fails ("Chromium distribution
  'chrome' is not found", "manifest unknown", EACCES on output files). Never install
  browsers on the host.
---

# Playwright on Bazzite (Docker only)

The host has no Chrome and no `sudo`, and `docker` is rootless Podman. Every browser
runs in a Microsoft image. Never run `npx playwright install` on the host.

## Rules for every run

- Add `--userns=keep-id` when the container writes into a bind mount. Without it, the
  container user maps to a foreign host uid and every write fails with `EACCES`.
- Add `:z` to every bind mount (SELinux).
- Add `--network host` to reach a dev server on the host's `localhost`.
- Add `--init --ipc=host` for one-off Chromium runs.
- Write output only under a mounted directory. Other paths vanish with the container.
- An image tag can lag the npm release (`manifest unknown`). List the tags and take
  the newest `-noble` one:
  `curl -s https://mcr.microsoft.com/v2/playwright/tags/list | tr ',' '\n' | grep -E '"v1\.[0-9]+\.[0-9]+-noble"' | tail -1`
- `page.setContent()` cannot load a `file://` stylesheet: the page renders unstyled with no error.
  Inline the CSS (`<style>` from `fs.readFileSync`). Prove a CSS check with a control case that
  must fail, and run it once against the old CSS.
- The images ship browsers, not the npm `playwright` package. Install the same
  version inside the container. The `playwright/python` image lacks its package too.
- The default headless browser (`chromium-headless-shell`) has no PDF viewer: an
  `<iframe>` or `<embed>` with a PDF stays blank, with no error. Launch with
  `chromium.launch({ channel: 'chromium' })` to render it.
- Before you trust a screenshot of a restarted dev server, `curl` the changed asset
  and `grep` for the change. A stale process on the same port serves the old build.

## Screenshot of a URL

```sh
docker run --rm --init --ipc=host --userns=keep-id -v "$PWD:/out:z" \
  mcr.microsoft.com/playwright:v1.63.0-noble \
  npx -y playwright@1.63.0 screenshot --full-page --wait-for-timeout 1000 \
  https://thetillhoff.de /out/shot.png
```

## Scripted flow (click, fill, assert)

Put `flow.js` (`require('playwright')`, `chromium.launch()`) in a directory, then:

```sh
docker run --rm --init --ipc=host --userns=keep-id --network host -v "$DIR:/work:z" -w /work \
  mcr.microsoft.com/playwright:v1.63.0-noble \
  bash -c "npm install playwright@1.63.0 --no-save --silent && node flow.js"
```

## Playwright MCP (`mcp__playwright__browser_*`)

A user-scope MCP server named `playwright` runs `mcr.microsoft.com/playwright/mcp`.
The `playwright@claude-plugins-official` plugin is disabled because it needs a host
Chrome. The output directory is mounted at the same path inside the container, so the
file paths that the tools return are valid on the host. Read screenshots from there.
`browser_file_upload` sees only that directory: copy the file into it first, or the call fails with `ENOENT`.

```sh
O=/var/home/$USER/.cache/playwright-mcp
claude mcp add --scope user playwright -- docker run -i --rm --init --userns=keep-id \
  --network host -v "$O:$O:z" -w "$O" mcr.microsoft.com/playwright/mcp:v0.0.82 --output-dir "$O"
```

To upgrade, run `claude mcp remove --scope user playwright` and add it again with a
newer tag (list the tags at `https://mcr.microsoft.com/v2/playwright/mcp/tags/list`).
A new MCP server loads only after Claude Code restarts.
