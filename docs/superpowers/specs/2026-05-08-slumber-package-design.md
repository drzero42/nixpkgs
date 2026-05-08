# slumber package — design

**Date:** 2026-05-08
**Source:** NixOS/nixpkgs PR #492613 (version 5.2.5)

## Summary

Add `slumber` (terminal-based HTTP/REST client, MIT, pure Rust) to the overlay. The package exists in upstream nixpkgs but the version bump PR is stuck; this overlay exposes the latest version in the meantime.

## Approach

Option A — minimal adaptation of the upstream derivation. Matches the `kagi-cli` pattern already in this repo.

## Files to create/modify

### New: `packages/slumber/default.nix`

```nix
{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "slumber";
  version = "5.2.5";

  src = fetchFromGitHub {
    owner = "LucasPickering";
    repo = "slumber";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6qdhBaX/YfRs5TWAjBxkTauBkX+8ppU+Xh6nYEMG7IE=";
  };

  cargoHash = "sha256-HiCyyvphFjYhuqXPa13Gq6QnxzQQ0KUy1S6w60dciXc=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Terminal-based HTTP/REST client";
    homepage = "https://slumber.lucaspickering.me";
    changelog = "https://github.com/LucasPickering/slumber/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "slumber";
    maintainers = with lib.maintainers; [ javaes ];
  };
})
```

Deviations from upstream:
- `nix-update-script { }` replaced with `passthru.updateScript = ./update.sh` (repo pattern)
- `versionCheckHook` / `doInstallCheck` omitted (not used by other packages here)

### New: `packages/slumber/update.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/slumber/default.nix slumber
```

Must be made executable (`chmod +x`).

### Modified: `flake.nix`

Add to `perSystem.packages`:
```nix
slumber = pkgs.callPackage ./packages/slumber { };
```

### Modified: `overlay.nix`

Add:
```nix
slumber = prev.callPackage ./packages/slumber { };
```

### Modified: `.github/workflows/update.yml`

Add `slumber` to the updater loop:
```bash
for pkg in claude-code holmesgpt kagi-cli slumber; do
```

## Platform support

No `meta.platforms` restriction — slumber is a pure Rust package that builds on all platforms. The flake's `systems` list (`x86_64-linux`, `aarch64-linux`) already limits what's exposed.

## Verification

After implementation: `nix build .#slumber` must succeed on both supported systems.
