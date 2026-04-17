#!/usr/bin/env bash
set -euo pipefail

# Return to original directory for nix-update
nix run github:Mic92/nix-update/1.13.1 -- --flake --override-filename packages/holmesgpt/default.nix holmesgpt
