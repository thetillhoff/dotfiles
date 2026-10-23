---
name: caddy-spa
description: Apply when writing or debugging a Caddyfile for a single-page app (SPA) that also reverse-proxies an API - e.g. a React/Vue/Svelte frontend served alongside an /api backend. Use when the user mentions Caddy plus SPA routing, API requests wrongly returning index.html, or try_files intercepting API routes. Fixes it with explicit handle blocks so try_files stops swallowing the proxy routes.
---

# Caddy SPA + API proxy

Use explicit `handle` blocks. Caddy's implicit directive order runs `try_files` before `reverse_proxy`, so without `handle`, `/api/*` gets rewritten to `/index.html` before the proxy rule can match.

```caddy
# Correct
:80 {
    handle /api/* {
        reverse_proxy backend:8000
    }
    handle {
        root * /srv
        try_files {path} /index.html
        file_server
    }
}
```

The `handle` block creates an explicit priority boundary: the first match wins, later blocks are skipped.

## Compression, deploy and secrets

- `encode gzip` is load-bearing: without it the JS chunk and large API responses go out raw. After a deploy that changes the Caddyfile, check `Content-Encoding: gzip` on `/assets/index-*.js`.
- A Caddyfile change ships only after a commit and an image rebuild.
- Never put an API secret into a `VITE_*` variable: Vite inlines it into the bundle. Add the token in the Caddy proxy hop from its environment.

## Type check of a Vite project

`npx tsc --noEmit` checks nothing when the root `tsconfig.json` has `"files": []` and project references. It exits 0 even for a file with syntax errors. Use `tsc -b`, or `npm run build` when the script is `tsc -b && vite build`.
