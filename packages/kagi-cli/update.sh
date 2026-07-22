#!/usr/bin/env bash
set -euo pipefail

NIX_UPDATE_VERSION=$(cat "$(dirname "$0")/../.nix-update-version")
nix run "github:Mic92/nix-update/${NIX_UPDATE_VERSION}" -- --flake --override-filename packages/kagi-cli/default.nix kagi-cli
