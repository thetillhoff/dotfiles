---
name: caddy-spa
description: Apply when writing a Caddyfile for a single-page app that also reverse-proxies an API. Prevents try_files from intercepting API routes.
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
