# kvitals v2.x repackage + auto-update — design

**Date:** 2026-06-10
**Status:** Approved (design)

## Problem

`packages/kvitals` is pinned to upstream `v1.3.0` and has no `update.sh`, so it
never auto-updates. The goal is to make kvitals auto-update like the other
packages in this flake.

A naive updater cannot simply be bolted on: between `v1.3.0` and the current
`v2.8.1`, upstream rewrote its data backend. The current derivation is built
around wrapping a shell script that no longer exists, so an auto-bump would fail
the build. The derivation must be rewritten for the v2.x layout first, then the
updater wired up.

## Background: what changed upstream (1.3.0 → 2.8.1)

- **Data source rewritten.** v1.3.0 collected metrics via
  `contents/scripts/sys-stats.sh`, a shell script spawning `awk`/`cat`/`ip`/`bc`
  and reading `lm_sensors`. v2.x reads native KSysGuard sensors directly from QML
  (`import org.kde.ksysguard.sensors`), the same backend KDE System Monitor uses.
  Confirmed in source, e.g. `CpuSensors.qml`:
  `Sensors.Sensor { sensorId: "cpu/all/usage" }`.
- **`contents/scripts/` deleted entirely.** No shell script, zero subprocesses
  (confirmed by grep across the v2.8.1 UI sources). Upstream's stated motivation
  was eliminating Plasma 6 Wayland FD-exhaustion crashes from the old CLI-pipe
  approach.
- **UI modularized.** `main.qml` became an orchestrator over `CompactView`/
  `FullView` plus seven per-metric sensor modules under `contents/ui/sensors/`.
- **New features:** GPU usage/VRAM/temp, CPU frequency, disk sensors, per-metric
  ordering/icons/colors configuration.
- **Plasma API unchanged:** `metadata.json` declares
  `"X-Plasma-API-Minimum-Version": "6.0"` in both versions, and
  `"KPackageStructure": "Plasma/Applet"`. Compatible with Plasma 6.6.

### NixOS / Plasma 6.6 compatibility

The widget is purpose-built for Plasma 6 and reads the same sensor backend as
KDE System Monitor. On a standard NixOS Plasma 6 desktop the `ksystemstats`
daemon and `libksysguard` QML modules are already present, so no extra runtime
binaries are required from the package. GPU sensors degrade gracefully via a
`hasGpuData` flag when the GPU backend isn't exposed.

## Design

Chosen approach: **minimal `stdenvNoCC` copy** — make the derivation reflect
what v2.x actually is (a pure QML plasmoid with no runtime binaries), removing
the now-dead wrapper and dependencies. Rejected alternatives: keeping
`makeWrapper` defensively (nothing to wrap), or pulling in extra KDE packaging
helpers (overkill for a plain plasmoid copy).

### 1. `packages/kvitals/default.nix`

- Function args reduce to `{ lib, stdenvNoCC, fetchFromGitHub }`. Removed:
  `makeWrapper, coreutils, gawk, procps, iproute2, bc, lm_sensors`.
- `version = "2.8.1"`; `src` keeps its shape (`fetchFromGitHub`, owner
  `yassine20011`, repo `kvitals`, `rev = "v${version}"`) with the new v2.8.1
  `hash`.
- `installPhase` copies the plasmoid into place, with no `wrapProgram`:

  ```
  runHook preInstall
  plasmoidDir=$out/share/plasma/plasmoids/org.kde.plasma.kvitals
  mkdir -p $plasmoidDir
  cp metadata.json $plasmoidDir/
  cp -r contents $plasmoidDir/
  runHook postInstall
  ```

- `meta` unchanged: `description`, `homepage`, `license = lib.licenses.gpl3Only`,
  `platforms = lib.platforms.linux`.

### 2. `packages/kvitals/update.sh`

Same pattern as `slumber`/`kagi-cli`, retargeted to kvitals, marked executable:

```bash
#!/usr/bin/env bash
set -euo pipefail
nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/kvitals/default.nix kvitals
```

nix-update's default `--version=stable` tracks the latest non-prerelease tag.
All kvitals releases are non-prerelease semver `vX.Y.Z` tags, so no
`--version-regex` is needed.

### 3. CI loop — `.github/workflows/update.yml`

- Add `kvitals` to the updater loop:
  `for pkg in claude-code holmesgpt kagi-cli kvitals openshift slumber; do`
- Remove the now-false `# kvitals has no updater` comment.

## Verification

- **Build gate (hard, run here):** `nix build .#kvitals` must succeed. This
  validates the new hash and the install layout.
- **Updater dry check (optional):** run `./packages/kvitals/update.sh` once to
  confirm it resolves to v2.8.1 and leaves a no-op diff.
- **Runtime functional check (manual, user's machine):** a Plasma widget cannot
  be exercised headless in this environment. Confirming the widget loads and
  sensors populate happens on the user's NixOS Plasma 6.6 machine post-merge.
  This is explicitly not claimed as verified by the implementer.

## Out of scope

- No changes to `flake.nix` / `overlay.nix` (kvitals already registered in both).
- No `holmesgpt` CI fix.
- No unrelated refactoring.
