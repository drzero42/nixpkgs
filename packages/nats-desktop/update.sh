#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/nats-desktop/default.nix nats-desktop
