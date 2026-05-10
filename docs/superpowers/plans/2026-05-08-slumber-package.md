# slumber Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `slumber` v5.2.5 (terminal HTTP/REST client) as a new package in this overlay, with an auto-updater wired into the scheduled CI workflow.

**Architecture:** A standard `rustPlatform.buildRustPackage` derivation adapted from nixpkgs PR #492613, following the same pattern as `kagi-cli`. Registered in both `flake.nix` (for `nix build .#slumber`) and `overlay.nix` (for downstream consumers). An `update.sh` script handles automated version bumps via `nix-update`.

**Tech Stack:** Nix, `rustPlatform.buildRustPackage`, `fetchFromGitHub`, `nix-update` (via `github:Mic92/nix-update/1.13.1`)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `packages/slumber/default.nix` | Package derivation |
| Create | `packages/slumber/update.sh` | Auto-updater script |
| Modify | `flake.nix` | Register in `perSystem.packages` |
| Modify | `overlay.nix` | Register in overlay |
| Modify | `.github/workflows/update.yml` | Add to scheduled updater loop |

---

### Task 1: Create the package derivation and updater

**Files:**
- Create: `packages/slumber/default.nix`
- Create: `packages/slumber/update.sh`

- [ ] **Step 1: Create the package directory**

```bash
mkdir packages/slumber
```

- [ ] **Step 2: Write `packages/slumber/default.nix`**

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

- [ ] **Step 3: Write `packages/slumber/update.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/slumber/default.nix slumber
```

- [ ] **Step 4: Make the updater executable**

```bash
chmod +x packages/slumber/update.sh
```

- [ ] **Step 5: Commit**

```bash
git add packages/slumber/
git commit -m "feat(slumber): add package v5.2.5"
```

---

### Task 2: Register in flake.nix and overlay.nix

**Files:**
- Modify: `flake.nix`
- Modify: `overlay.nix`

- [ ] **Step 1: Add slumber to `flake.nix`**

In `flake.nix`, the `packages` attrset currently ends with:
```nix
            kvitals = pkgs.callPackage ./packages/kvitals { };
```

Add slumber after it:
```nix
            kvitals = pkgs.callPackage ./packages/kvitals { };
            slumber = pkgs.callPackage ./packages/slumber { };
```

- [ ] **Step 2: Add slumber to `overlay.nix`**

Current content:
```nix
final: prev: {
  claude-code   = prev.callPackage ./packages/claude-code { };
  kagi-cli      = prev.callPackage ./packages/kagi-cli { };
  kvitals       = prev.callPackage ./packages/kvitals { };
}
```

Add slumber (alphabetical):
```nix
final: prev: {
  claude-code   = prev.callPackage ./packages/claude-code { };
  kagi-cli      = prev.callPackage ./packages/kagi-cli { };
  kvitals       = prev.callPackage ./packages/kvitals { };
  slumber       = prev.callPackage ./packages/slumber { };
}
```

- [ ] **Step 3: Verify the flake evaluates without errors**

```bash
nix flake show
```

Expected: `slumber` appears under `packages.x86_64-linux` (and `aarch64-linux`) with no evaluation errors.

- [ ] **Step 4: Commit**

```bash
git add flake.nix overlay.nix
git commit -m "feat(slumber): register in flake and overlay"
```

---

### Task 3: Wire into CI updater

**Files:**
- Modify: `.github/workflows/update.yml`

- [ ] **Step 1: Add slumber to the updater loop**

In `.github/workflows/update.yml`, change:
```yaml
          for pkg in claude-code holmesgpt kagi-cli; do
```
to:
```yaml
          for pkg in claude-code holmesgpt kagi-cli slumber; do
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/update.yml
git commit -m "ci: add slumber to scheduled updater loop"
```

---

### Task 4: Build and verify

- [ ] **Step 1: Build the package**

```bash
nix build .#slumber
```

Expected: build completes successfully, `./result/bin/slumber` exists.

- [ ] **Step 2: Smoke-test the binary**

```bash
./result/bin/slumber --version
```

Expected: output contains `5.2.5`.

- [ ] **Step 3: Run formatter and commit any changes**

```bash
nix fmt
git diff
```

If there are changes:
```bash
git add -u
git commit -m "style: nix fmt"
```
