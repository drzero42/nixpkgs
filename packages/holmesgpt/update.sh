#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
PKG_DIR=packages/holmesgpt

NIX_UPDATE_VERSION=$(cat packages/.nix-update-version)
nix run "github:Mic92/nix-update/${NIX_UPDATE_VERSION}" -- \
  --flake --override-filename "$PKG_DIR/default.nix" holmesgpt

# Upstream uses Poetry; regenerate the vendored uv.lock that uv2nix consumes,
# constrained to the versions in upstream's poetry.lock.
SRC=$(nix build --no-link --print-out-paths .#holmesgpt.src)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -r --no-preserve=mode "$SRC/." "$WORK"
nix shell nixpkgs#migrate-to-uv nixpkgs#uv nixpkgs#python313 -c \
  migrate-to-uv --skip-uv-checks --keep-current-build-backend "$WORK"
cp "$WORK/pyproject.toml" "$WORK/uv.lock" "$PKG_DIR/"
