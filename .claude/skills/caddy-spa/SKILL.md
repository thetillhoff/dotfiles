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
