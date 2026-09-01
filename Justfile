# helmctl (truvity/ocictl) — deterministic chart packaging. Pinned, and
# run through `go run` so there is nothing to install.
# renovate: datasource=github-releases depName=truvity/ocictl
HELMCTL_VERSION := "v0.5.1"

default: check

# Everything CI runs, locally.
check: lint template required image-pin

lint:
    helm lint charts/netbox-mcp-upstream --set netbox.url=http://netbox --set netbox.existingSecret=nb

template:
    @helm template nm charts/netbox-mcp-upstream \
        --set netbox.url=http://netbox.netbox.svc \
        --set netbox.existingSecret=netbox-mcp-token >/dev/null && echo "ok: minimal"
    @helm template nm charts/netbox-mcp-upstream \
        --set netbox.url=http://netbox.netbox.svc \
        --set netbox.existingSecret=netbox-mcp-token \
        --set mcpAuth.existingSecret=netbox-mcp-auth >/dev/null && echo "ok: with MCP_AUTH_TOKEN"

# The token must never be accepted as a literal, and a missing URL must
# fail loudly at render rather than produce a pod that dials nothing.
required:
    @! helm template nm charts/netbox-mcp-upstream >/dev/null 2>&1 && echo "ok: refuses to render without netbox.url/existingSecret" \
      || { echo "FAIL: rendered without required values"; exit 1; }

# Releasing THIS chart must never change which upstream image runs, so
# the tag is pinned and must not resolve through appVersion.
image-pin:
    @helm template nm charts/netbox-mcp-upstream \
        --set netbox.url=http://x --set netbox.existingSecret=y \
      | grep -oE 'netbox-mcp-server:[0-9.]+' | head -1

# Deterministic local package — same tool CI publishes with, so a chart
# built here has the same digest as the released one.
package version="0.0.0-dev":
    go run github.com/truvity/ocictl/cmd/helmctl@{{HELMCTL_VERSION}} package \
        --chart charts/netbox-mcp-upstream --version {{version}} --destination dist/

release-check:
    goreleaser check
