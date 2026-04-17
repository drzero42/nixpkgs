#!/usr/bin/env bash
set -euo pipefail

version=$(npm view @anthropic-ai/claude-code version)

# Generate updated lock file
cd "$(dirname "${BASH_SOURCE[0]}")"
npm i --package-lock-only @anthropic-ai/claude-code@"$version"
rm -f package.json

# Update version and hashes
cd -
nix run github:Mic92/nix-update/1.13.1 -- --flake --override-filename packages/claude-code/default.nix --version "$version" claude-code
