#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
PKG_DIR=packages/unifi-network-mcp

latest=$(curl -fsSL https://pypi.org/pypi/unifi-network-mcp/json | jq -r .info.version)
current=$(sed -nE 's/.*"unifi-network-mcp==([^"]+)".*/\1/p' "$PKG_DIR/pyproject.toml")

# Only relock on a new release; relocking every run would churn the
# transitive pins whenever any dependency publishes.
if [[ "$latest" == "$current" ]]; then
  echo "unifi-network-mcp is up to date ($current)"
  exit 0
fi

sed -i -E "s/\"unifi-network-mcp==[^\"]+\"/\"unifi-network-mcp==${latest}\"/" "$PKG_DIR/pyproject.toml"
nix shell nixpkgs#uv nixpkgs#python313 -c uv lock --upgrade --project "$PKG_DIR"
echo "unifi-network-mcp: $current -> $latest"
