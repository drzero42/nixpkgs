#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake \
  --override-filename packages/openshift/default.nix \
  --version-regex 'openshift-clients-(.+)' \
  openshift
