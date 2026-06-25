# Design: Package `nats-desktop` for Nix

Date: 2026-06-25
Status: Approved

## Goal

Add `nats-desktop` ([thedataflows/nats-desktop](https://github.com/thedataflows/nats-desktop))
to this flake's overlay so it can be installed on NixOS hosts. No existing Nix
packaging is known to exist.

## Upstream facts

- **Language/UI:** Go 1.25 + [Gio](https://gioui.org) (immediate-mode, cgo-based native GUI).
- **License:** MIT.
- **Latest tag:** `v0.3.0`.
- **Dependencies:** vendored in-repo (`vendor/` directory present).
- **Main package:** built via `go run ./cmd/nats-desktop` per upstream README.
- **Icons:** ships `assets/icons/nats-plain-{32,64,128,256,512}px.png`.
- **Notable cgo deps:** Gio (Wayland/X11/GL/Vulkan), `github.com/sqweek/dialog`
  (native file dialogs — likely GTK on Linux).

## Decisions

- **Build from source** with `buildGoModule` (not the prebuilt release tarball).
  Reproducible, matches repo conventions, avoids `autoPatchelf` on a dynamically
  linked GUI binary.
- **Full desktop integration:** install a `.desktop` entry and the bundled PNG
  icons so the app appears in DE app menus.
- **Platforms:** `x86_64-linux` only (the arch we can build-test here).

## Implementation

### Files

- `packages/nats-desktop/default.nix` — `callPackage`-shaped `buildGoModule` derivation.
- `packages/nats-desktop/update.sh` — standard `nix-update` wrapper, executable:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  nix run github:Mic92/nix-update/1.13.1 -- \
    --flake --override-filename packages/nats-desktop/default.nix nats-desktop
  ```

- Register in `flake.nix` (`perSystem.packages.nats-desktop = pkgs.callPackage ./packages/nats-desktop { };`).
- Register in `overlay.nix` (`nats-desktop = prev.callPackage ./packages/nats-desktop { };`).
- Add `nats-desktop` to the updater loop in `.github/workflows/update.yml`.

### Derivation shape

- `pname = "nats-desktop"`, `version = "0.3.0"`.
- `src = fetchFromGitHub { owner = "thedataflows"; repo = "nats-desktop"; tag = "v${finalAttrs.version}"; hash = ...; }`.
- `vendorHash = null` — deps vendored, no Go-module FOD to maintain.
- `subPackages = [ "cmd/nats-desktop" ]` (confirm exact main path during build).
- `nativeBuildInputs = [ pkg-config copyDesktopItems ]`.
- `buildInputs` (empirically confirmed by building): expected
  `[ wayland libxkbcommon libGL vulkan-loader xorg.libX11 xorg.libXcursor xorg.libXfixes ]`,
  plus `gtk3` if `sqweek/dialog` requires it.
- Gio `dlopen`s GL/Wayland/Vulkan at runtime, so add a runtime library path via
  `postFixup` `patchelf --add-rpath ${lib.makeLibraryPath buildInputs}` (or a
  wrapper). A binary that links but can't `dlopen` its renderer is a silent
  runtime failure.
- `passthru.updateScript = ./update.sh;`.

### Desktop integration

- `makeDesktopItem`: Name "NATS Desktop", Exec `nats-desktop`, Icon `nats-desktop`,
  Categories `Development;Network;`.
- `postInstall`: install each `assets/icons/nats-plain-NNpx.png` to
  `$out/share/icons/hicolor/<size>x<size>/apps/nats-desktop.png`.

### meta

```nix
meta = {
  description = "Cross-platform desktop GUI for NATS";
  homepage = "https://github.com/thedataflows/nats-desktop";
  license = lib.licenses.mit;
  mainProgram = "nats-desktop";
  platforms = [ "x86_64-linux" ];
};
```

## Verification

1. `nix build .#nats-desktop` succeeds.
2. `patchelf --print-rpath result/bin/nats-desktop` (or `ldd`) shows GL/Wayland
   libs resolve — proves runtime renderer deps are reachable.
3. `nix run .#nats-desktop` launches (best-effort; needs a display).
4. `nix fmt` clean, then commit.

## Risks / unknowns

- Exact `buildInputs` set and runtime-library wiring for Gio — resolved
  iteratively during the build, not guessed.
- Whether `sqweek/dialog` drags in GTK on Linux — confirmed at build time.
