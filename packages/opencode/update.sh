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
echo "opencode: ${CURRENT} -> ${VERSION}"
