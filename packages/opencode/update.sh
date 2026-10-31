#!/usr/bin/env bash
set -euo pipefail

# v2 ships as git tags + the @opencode/cli npm package, not GitHub Releases,
# so take the version from npm's `latest` dist-tag.
# nix-update can't be used: the package imports upstream's nix/ from src
# (import-from-derivation), which nix-update's read-only eval can't realise.

FILE="$(dirname "$0")/default.nix"
VERSION=$(curl -fsSL https://registry.npmjs.org/@opencode%2fcli/latest | jq -r .version)
CURRENT=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$FILE")

[ "$VERSION" = "$CURRENT" ] && exit 0

HASH=$(nix flake prefetch --json "github:anomalyco/opencode/v${VERSION}" | jq -r .hash)
sed -i \
  -e "s|^  version = \".*\";|  version = \"${VERSION}\";|" \
  -e "s|^    hash = \".*\";|    hash = \"${HASH}\";|" \
  "$FILE"

# The tag's nix/hashes.json lags the tag (see default.nix), so build
# node_modules with a fake hash and take the real one from the mismatch.
set_nm_hash() { sed -i "s|^  nodeModulesHash = \".*\";|  nodeModulesHash = \"$1\";|" "$FILE"; }
set_nm_hash "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
NM_HASH=$({ nix build --no-link .#opencode.node_modules 2>&1 || true; } | sed -n 's/^ *got: *//p')
if [ -z "$NM_HASH" ]; then
  echo "opencode: could not compute the node_modules hash" >&2
  exit 1
fi
set_nm_hash "$NM_HASH"
echo "opencode: ${CURRENT} -> ${VERSION}"
