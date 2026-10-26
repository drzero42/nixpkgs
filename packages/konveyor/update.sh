#!/usr/bin/env bash
set -euo pipefail

# Upstream has no releases, so track a branch. source.nix is shared with konveyor-widgets.
NIX_UPDATE_VERSION=$(cat "$(dirname "$0")/../.nix-update-version")
nix run "github:Mic92/nix-update/${NIX_UPDATE_VERSION}" -- \
  --flake --version=branch=drzero42 --override-filename packages/konveyor/source.nix konveyor
