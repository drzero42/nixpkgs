# nats-desktop Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `nats-desktop` package (Go + Gio GUI for NATS) to this flake's overlay, installable on x86_64-linux NixOS hosts with a desktop launcher.

**Architecture:** A `buildGoModule` derivation that builds from the upstream GitHub source (vendored deps → `vendorHash = null`), links the Gio cgo system libraries, wires runtime library paths for `dlopen`ed renderers, and installs a `.desktop` entry plus hicolor icons. Registered in `flake.nix`, `overlay.nix`, and the CI updater loop.

**Tech Stack:** Nix (flake-parts), `buildGoModule`, Gio, `makeDesktopItem`/`copyDesktopItems`, `nix-update`.

## Global Constraints

- Package name (`pname`, attr, overlay key, update path): `nats-desktop`.
- Version: `0.3.0`, upstream tag `v0.3.0`.
- License: MIT (`lib.licenses.mit`).
- `meta.platforms = [ "x86_64-linux" ]` (no aarch64, no darwin).
- `meta.mainProgram = "nats-desktop"`.
- `vendorHash = null` (deps vendored upstream).
- Formatting: `nix fmt` (nixfmt-rfc-style) must be clean before any commit.
- No CI builds exist; correctness is proven locally via `nix build` + rpath/runtime check.
- Follow the "Adding a new package" checklist in `CLAUDE.md` exactly.

---

### Task 1: Skeleton derivation that fetches source

**Files:**
- Create: `packages/nats-desktop/default.nix`

**Interfaces:**
- Produces: a `callPackage`-shaped function `{ lib, buildGoModule, fetchFromGitHub, ... }: buildGoModule (finalAttrs: { ... })` exposing `pname = "nats-desktop"`, `version = "0.3.0"`.

- [ ] **Step 1: Write a minimal derivation with a placeholder src hash**

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "nats-desktop";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "thedataflows";
    repo = "nats-desktop";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  vendorHash = null;

  meta = {
    description = "Cross-platform desktop GUI for NATS";
    homepage = "https://github.com/thedataflows/nats-desktop";
    license = lib.licenses.mit;
    mainProgram = "nats-desktop";
    platforms = [ "x86_64-linux" ];
  };
})
```

- [ ] **Step 2: Resolve the real src hash**

Run: `nix-prefetch-url --unpack https://github.com/thedataflows/nats-desktop/archive/refs/tags/v0.3.0.tar.gz 2>/dev/null | tail -1 | xargs nix hash convert --to sri --hash-algo sha256`
Expected: an `sha256-...` SRI string. Replace `lib.fakeHash` in the `src.hash` with it.

(Alternative if that errors: temporarily register the package per Task 5, run `nix build .#nats-desktop` and copy the `got: sha256-...` from the hash-mismatch error.)

- [ ] **Step 3: Verify eval works**

Run: `nix-instantiate --eval -E 'with import <nixpkgs> {}; (callPackage ./packages/nats-desktop {}).pname'`
Expected: `"nats-desktop"` (eval succeeds, no missing-arg or syntax error).

- [ ] **Step 4: Commit**

```bash
git add packages/nats-desktop/default.nix
git commit -m "feat(nats-desktop): skeleton derivation with pinned source"
```

---

### Task 2: Register the package so it builds via the flake

**Files:**
- Modify: `flake.nix` (add to `perSystem.packages`)
- Modify: `overlay.nix` (add overlay attr)

**Interfaces:**
- Consumes: `packages/nats-desktop/default.nix` from Task 1.
- Produces: flake output `packages.x86_64-linux.nats-desktop`; overlay attr `nats-desktop`.

- [ ] **Step 1: Add to `flake.nix` packages set**

In the `packages = { ... };` block, after the `kvitals` line, add:

```nix
            nats-desktop = pkgs.callPackage ./packages/nats-desktop { };
```

- [ ] **Step 2: Add to `overlay.nix`**

After the `kvitals` line, add:

```nix
  nats-desktop  = prev.callPackage ./packages/nats-desktop { };
```

- [ ] **Step 3: Verify the attr resolves**

Run: `nix eval .#nats-desktop.pname`
Expected: `"nats-desktop"`

- [ ] **Step 4: Commit**

```bash
git add flake.nix overlay.nix
git commit -m "feat(nats-desktop): register in flake and overlay"
```

---

### Task 3: Make the Go build succeed (Gio system deps)

This is the empirical core. The Gio toolkit needs cgo system libraries at build time. Discover the exact set by building and reading errors.

**Files:**
- Modify: `packages/nats-desktop/default.nix`

**Interfaces:**
- Consumes: registered flake attr from Task 2.
- Produces: a derivation whose `nix build .#nats-desktop` completes and yields `result/bin/nats-desktop`.

- [ ] **Step 1: Add the expected build inputs and subPackages**

Add these args to the function head: `pkg-config, wayland, libxkbcommon, libGL, vulkan-loader, xorg, gtk3`. Inside the derivation (after `vendorHash`):

```nix
  subPackages = [ "cmd/nats-desktop" ];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    wayland
    libxkbcommon
    libGL
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXfixes
    gtk3
  ];

  ldflags = [ "-s" "-w" ];
```

- [ ] **Step 2: Build and read errors**

Run: `nix build .#nats-desktop -L 2>&1 | tail -40`
Expected: ideally success. If it fails with `cmd/nats-desktop: no such directory`, find the real main path:
`curl -s "https://api.github.com/repos/thedataflows/nats-desktop/git/trees/v0.3.0?recursive=1" | jq -r '.tree[].path' | grep -E 'main\.go$|^cmd/'`
and fix `subPackages`. If it fails with a `pkg-config: package X not found` or missing C header, add the corresponding nixpkgs lib to `buildInputs` and rebuild. Iterate until the build succeeds.

- [ ] **Step 3: Confirm the binary exists**

Run: `test -x result/bin/nats-desktop && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add packages/nats-desktop/default.nix
git commit -m "feat(nats-desktop): build from source with Gio system deps"
```

---

### Task 4: Wire runtime library paths (Gio dlopen)

Gio `dlopen`s GL/Wayland/Vulkan/xkbcommon at runtime; a binary that builds may still fail to start because those libs are not on its RUNPATH. Make them reachable.

**Files:**
- Modify: `packages/nats-desktop/default.nix`

**Interfaces:**
- Consumes: building derivation from Task 3.
- Produces: a binary whose RUNPATH includes the runtime renderer libs.

- [ ] **Step 1: Inspect current rpath**

Run: `patchelf --print-rpath result/bin/nats-desktop`
Expected: note whether the `buildInputs` lib dirs are present. Go binaries typically have a minimal RUNPATH, so the `dlopen`ed libs are likely missing.

- [ ] **Step 2: Add `nativeBuildInputs` patchelf and a postFixup rpath**

Add `patchelf` to `nativeBuildInputs`. Add after `ldflags`:

```nix
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath finalAttrs.buildInputs} $out/bin/nats-desktop
  '';
```

- [ ] **Step 3: Rebuild and re-check rpath**

Run: `nix build .#nats-desktop -L && patchelf --print-rpath result/bin/nats-desktop | tr ':' '\n' | grep -E 'mesa|libGL|wayland|vulkan|xkbcommon|libX11' | head`
Expected: at least the mesa/libGL, wayland, vulkan, and xkbcommon store paths appear.

- [ ] **Step 4: Best-effort runtime smoke test**

Run: `timeout 8 nix run .#nats-desktop 2>&1 | head -20; echo "exit: $?"`
Expected: it either opens a window or fails on *display/connection* (`no display`, `cannot open display`, Wayland socket) — NOT on a missing `.so` (`error while loading shared libraries` / `failed to load libGL`). A missing-`.so` error means go back to Step 2 and add the lib. Document the observed outcome.

- [ ] **Step 5: Commit**

```bash
git add packages/nats-desktop/default.nix
git commit -m "feat(nats-desktop): add runtime rpath for Gio dlopened libs"
```

---

### Task 5: Desktop entry and icons

**Files:**
- Modify: `packages/nats-desktop/default.nix`

**Interfaces:**
- Consumes: working build from Task 4.
- Produces: `$out/share/applications/nats-desktop.desktop` and `$out/share/icons/hicolor/<size>x<size>/apps/nats-desktop.png`.

- [ ] **Step 1: Add desktop item + icon install**

Add `makeDesktopItem, copyDesktopItems` to the function head and `copyDesktopItems` to `nativeBuildInputs`. Add to the derivation:

```nix
  desktopItems = [
    (makeDesktopItem {
      name = "nats-desktop";
      desktopName = "NATS Desktop";
      exec = "nats-desktop";
      icon = "nats-desktop";
      comment = "Cross-platform desktop GUI for NATS";
      categories = [ "Development" "Network" ];
    })
  ];

  postInstall = ''
    for size in 32 64 128 256 512; do
      install -Dm644 assets/icons/nats-plain-''${size}px.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/nats-desktop.png
    done
  '';
```

Note: keep the Task 4 `postFixup` block; `postInstall` runs before `postFixup`, so both coexist.

- [ ] **Step 2: Rebuild and verify desktop + icon files**

Run: `nix build .#nats-desktop -L && ls result/share/applications/ && ls result/share/icons/hicolor/256x256/apps/`
Expected: `nats-desktop.desktop` and `nats-desktop.png` listed.

- [ ] **Step 3: Validate the desktop file**

Run: `desktop-file-validate result/share/applications/nats-desktop.desktop && echo VALID`
Expected: `VALID` (or no error output). If `desktop-file-validate` is unavailable, `grep -E 'Exec=|Icon=|Categories=' result/share/applications/nats-desktop.desktop` and eyeball it.

- [ ] **Step 4: Commit**

```bash
git add packages/nats-desktop/default.nix
git commit -m "feat(nats-desktop): install desktop entry and icons"
```

---

### Task 6: Auto-update script and CI registration

**Files:**
- Create: `packages/nats-desktop/update.sh`
- Modify: `.github/workflows/update.yml`

**Interfaces:**
- Consumes: nothing from prior tasks at runtime; mirrors existing updater pattern (`packages/slumber/update.sh`).
- Produces: an executable `update.sh` and a CI loop entry.

- [ ] **Step 1: Write `update.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/nats-desktop/default.nix nats-desktop
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x packages/nats-desktop/update.sh && test -x packages/nats-desktop/update.sh && echo OK`
Expected: `OK`

- [ ] **Step 3: Add `passthru.updateScript` to the derivation**

In `packages/nats-desktop/default.nix`, add after `ldflags` (or near `meta`):

```nix
  passthru.updateScript = ./update.sh;
```

- [ ] **Step 4: Register in the CI updater loop**

Read `.github/workflows/update.yml`, find where the other packages' `update.sh` scripts are invoked (the loop/list), and add `nats-desktop` following the exact same pattern used for `slumber`/`kvitals`. Match surrounding syntax precisely.

- [ ] **Step 5: Verify the workflow still parses**

Run: `python3 -c 'import yaml,sys; yaml.safe_load(open(".github/workflows/update.yml")); print("YAML OK")'`
Expected: `YAML OK`

- [ ] **Step 6: Rebuild to confirm `updateScript` addition didn't break eval**

Run: `nix build .#nats-desktop -L && echo BUILD_OK`
Expected: `BUILD_OK`

- [ ] **Step 7: Commit**

```bash
git add packages/nats-desktop/update.sh .github/workflows/update.yml packages/nats-desktop/default.nix
git commit -m "feat(nats-desktop): add updater script and CI registration"
```

---

### Task 7: Final verification and formatting

**Files:**
- Modify: `packages/nats-desktop/default.nix` (formatting only, if needed)

- [ ] **Step 1: Format**

Run: `nix fmt`
Expected: completes; `git diff --stat` shows only whitespace/formatting changes if any.

- [ ] **Step 2: Final clean build**

Run: `nix build .#nats-desktop -L && echo BUILD_OK`
Expected: `BUILD_OK`

- [ ] **Step 3: Final rpath assertion**

Run: `patchelf --print-rpath result/bin/nats-desktop | tr ':' '\n' | grep -cE 'mesa|libGL|wayland|vulkan|xkbcommon'`
Expected: a count `>= 3`.

- [ ] **Step 4: Commit any formatting changes**

```bash
git add -A
git commit -m "style(nats-desktop): nix fmt" || echo "nothing to format"
```

---

## Self-Review Notes

- **Spec coverage:** from-source buildGoModule (T1,T3) · vendorHash=null (T1) · src pin (T1) · flake+overlay registration (T2) · Gio buildInputs (T3) · runtime dlopen rpath (T4) · desktop entry + hicolor icons (T5) · update.sh + CI loop (T6) · meta/platforms x86_64-linux (T1) · nix fmt + build verification (T7). All spec sections mapped.
- **Empirical items** (exact buildInputs, main package path, rpath necessity) are deliberately resolved inside Task 3/4 build loops with concrete diagnostic commands rather than guessed.
