# TLS, DNS and ingress

## cert-manager with Gateway API

- The annotation `cert-manager.io/cluster-issuer` on a Gateway makes cert-manager create a Certificate per listener.
- Listeners with the same `certificateRefs[0].name` share one multi-SAN certificate. Unique names give one certificate each.
- A gateway that the ACME server cannot reach needs DNS-01. HTTP-01 fails there. Scope the DNS token to the one zone.

## Cloudflare in front of an HTTPS origin

- The zone SSL mode decides how the Cloudflare edge fetches the origin. In `flexible` mode it uses cleartext port 80. An HTTP-to-HTTPS redirect route on the origin then makes an endless redirect loop (Firefox: "The page isn't redirecting properly"). Use `strict`.
- `strict` needs a publicly trusted origin certificate for each proxied hostname. Without it the edge answers 526.
- To set the SSL mode, the API token needs `Zone > Zone Settings > Edit`. Without it the call fails with `9109 Unauthorized`.
- Diagnose the loop: compare the edge with the origin. An origin that answers 200 while the edge answers 301 confirms it.

```sh
curl -sSI https://<host>/
curl -sSI --resolve <host>:443:<node-ip> https://<host>/
```

## external-dns deletes records when an annotation changes meaning

With `policy: sync` and a TXT registry, external-dns deletes every record it no longer sees. A chart bump can change what it reads. Chart 1.15 to 1.23 moved the default annotation prefix from `external-dns.alpha.kubernetes.io/` to `external-dns.kubernetes.io/`. Read the changelog before a bump. Compare `dig` of the managed names before and after.

## HTTP/3 behind a port forward

- A proxy that advertises `alt-svc: h3=":<port>"` for a port that is not forwarded (or not the port the client used) black-holes QUIC.
- Chrome and Firefox race QUIC against TCP and fall back at once. WebKit (every iOS browser) keeps the cached Alt-Svc for its `ma` lifetime (for example 30 days) and hangs.
- Turn HTTP/3 off in Caddy: `servers { protocols h1 h2 }`.
- A device that already has the entry needs Safari website data cleared. A Private tab uses an empty store, so it is the cheap test.
- Gateway API `protocol: HTTPS` is TLS over TCP by specification. HTTP/3 needs a custom UDP listener or an edge that serves it.
