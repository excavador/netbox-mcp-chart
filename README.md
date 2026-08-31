# netbox-mcp-chart

Helm chart for [netbox-mcp-server](https://github.com/netboxlabs/netbox-mcp-server) —
read-only [Model Context Protocol](https://modelcontextprotocol.io) access to a
NetBox instance.

```
oci://ghcr.io/opwerm/charts/netbox-mcp
```

This packages the upstream image; it does not build one. Upstream publishes
multi-arch images (`linux/amd64`, `linux/arm64`), so this runs on arm64 nodes
unmodified.

## Why a separate chart

Upstream ships a container and a compose file but no chart. The interesting
part is not the Deployment — it is the defaults:

- **The NetBox API token is never a literal.** `netbox.existingSecret` is
  required and the chart refuses to render without it, so a token cannot end
  up in a values file or in git.
- **`HOST` is forced to `0.0.0.0`.** Upstream defaults to `127.0.0.1`, which in
  a pod means nothing can reach it, including the readiness probe.
- **Probes are TCP, not HTTP.** Once `MCP_AUTH_TOKEN` is set the `/mcp`
  endpoint answers 401, and an HTTP probe would crash-loop a healthy server on
  its own authentication.
- **Restricted-PSA clean**: non-root, read-only root filesystem, all
  capabilities dropped, seccomp `RuntimeDefault`.
- **No CPU limit.** CFS quota throttles bursty request handling even when
  average usage sits far below the limit. Memory is capped so a runaway dies
  instead of pressuring the node.

## Minimal values

```yaml
netbox:
  url: http://netbox.netbox.svc
  existingSecret: netbox-mcp-token   # key: token
```

## Authentication

`mcpAuth.existingSecret` sets the server's own static bearer token. It is
**defence in depth**, not the primary control, when the endpoint is exposed
through a gateway that validates OIDC JWTs — there it only guards against
something reaching the Service directly and bypassing the gateway.

The MCP endpoint is served at **`/mcp`**.

## Versioning

The chart version and `appVersion` move independently. `appVersion` and
`image.tag` track the upstream release and are moved together by Renovate;
releasing the chart never changes which upstream image runs.

## Licence

MIT. The upstream server is a separate project under its own licence.
