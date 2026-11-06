#!/usr/bin/env bash
set -euo pipefail

# Three release assets, one hash each; nix-update only bumps one hash per
# derivation. releases/latest skips pre-releases and drafts (upstream ships both).

FILE="$(dirname "$0")/default.nix"
REPO=vrtmrz/obsidian-livesync
ASSETS=(main.js manifest.json styles.css)
AUTH=()
[ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

VERSION=$(curl -fsSL "${AUTH[@]}" -H 'Accept: application/vnd.github+json' \
  "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name)
CURRENT=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$FILE")

if [ -z "$VERSION" ] || [ "$VERSION" = null ]; then
  echo "obsidian-livesync: could not determine the latest release" >&2
  exit 1
fi
[ "$VERSION" = "$CURRENT" ] && exit 0

# Prefetch everything before touching the file, so a failed download leaves it as it was.
declare -A HASHES
for asset in "${ASSETS[@]}"; do
  HASHES[$asset]=$(nix store prefetch-file --json \
    "https://github.com/${REPO}/releases/download/${VERSION}/${asset}" | jq -r .hash)
done

# Rewrite one line, failing if the pattern no longer matches default.nix.
replace() {
  grep -q "$1" "$FILE" || { echo "obsidian-livesync: no line matches $1 in $FILE" >&2; exit 1; }
  sed -i "s|$1|$2|" "$FILE"
}
for asset in "${ASSETS[@]}"; do
  replace "^    \"${asset}\" = \".*\";" "    \"${asset}\" = \"${HASHES[$asset]}\";"
done
replace '^  version = ".*";' "  version = \"${VERSION}\";"
echo "obsidian-livesync: ${CURRENT} -> ${VERSION}"
