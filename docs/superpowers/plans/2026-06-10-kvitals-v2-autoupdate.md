# kvitals v2.x Repackage + Auto-Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repackage `kvitals` for its rewritten v2.x layout and wire it into the scheduled auto-updater so it tracks upstream releases.

**Architecture:** Upstream rewrote kvitals between v1.3.0 and v2.8.1 from a shell-script data collector to a pure QML plasmoid reading native KSysGuard sensors. The derivation drops `makeWrapper` and all runtime binary dependencies and becomes a plain `metadata.json` + `contents/` copy. A standard `nix-update` `update.sh` (matching the other packages) plus a one-line CI loop edit complete the auto-update wiring.

**Tech Stack:** Nix (`stdenvNoCC`, `fetchFromGitHub`), `nix-update`, GitHub Actions.

**Design spec:** `docs/superpowers/specs/2026-06-10-kvitals-v2-autoupdate-design.md`

**Branch:** All work happens on `kvitals-v2-autoupdate` (already created off
`origin/main`; carries the spec and plan commits). `main` is untouched until the
PR merges. The plan ends by opening a PR — see the final task. Do not commit to
`main` directly.

---

## File Structure

- `packages/kvitals/default.nix` — Modify: rewrite for v2.x (args, version, hash, installPhase).
- `packages/kvitals/update.sh` — Create: nix-update auto-update script.
- `.github/workflows/update.yml` — Modify: add `kvitals` to the updater loop, drop the stale comment.

No changes to `flake.nix` / `overlay.nix` — `kvitals` is already registered in both.

---

## Task 1: Rewrite `packages/kvitals/default.nix` for v2.x

**Files:**
- Modify: `packages/kvitals/default.nix` (full rewrite of the file)

- [ ] **Step 1: Replace the derivation with the v2.x version, using a fake hash**

Write `packages/kvitals/default.nix` with exactly this content (note `hash` is the
fake placeholder — it will be corrected in Step 3):

```nix
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kvitals";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "yassine20011";
    repo = "kvitals";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  installPhase = ''
    runHook preInstall

    plasmoidDir=$out/share/plasma/plasmoids/org.kde.plasma.kvitals
    mkdir -p $plasmoidDir
    cp metadata.json $plasmoidDir/
    cp -r contents $plasmoidDir/

    runHook postInstall
  '';

  meta = {
    description = "Live system vitals in the KDE Plasma panel: CPU, RAM, Temp, Battery, Network";
    homepage = "https://github.com/yassine20011/kvitals";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
```

- [ ] **Step 2: Run the build to obtain the real hash**

Run: `nix build .#kvitals 2>&1 | tee /tmp/kvitals-build.log`
Expected: FAIL with a hash mismatch error containing a `got: sha256-...` line for
the `src` fetch. Copy that `got:` value.

- [ ] **Step 3: Set the real source hash**

Replace the fake hash line in `packages/kvitals/default.nix` with the `got:` value
from Step 2:

```nix
    hash = "sha256-<value-from-step-2>";
```

- [ ] **Step 4: Run the build to verify it passes**

Run: `nix build .#kvitals`
Expected: PASS (exit 0), produces a `result` symlink.

- [ ] **Step 5: Verify the plasmoid layout in the build output**

Run: `ls result/share/plasma/plasmoids/org.kde.plasma.kvitals/`
Expected: lists `metadata.json` and `contents`.

Run: `test -f result/share/plasma/plasmoids/org.kde.plasma.kvitals/metadata.json && grep -q '"Version": "2.8.1"' result/share/plasma/plasmoids/org.kde.plasma.kvitals/metadata.json && echo OK`
Expected: prints `OK`.

- [ ] **Step 6: Format**

Run: `nix fmt -- packages/kvitals/default.nix`
Expected: exit 0 (file already formatted or reformatted in place).

- [ ] **Step 7: Commit**

```bash
git add packages/kvitals/default.nix
git commit -m "kvitals: repackage for v2.x layout, bump to 2.8.1"
```

---

## Task 2: Add the auto-update script

**Files:**
- Create: `packages/kvitals/update.sh`

- [ ] **Step 1: Create `packages/kvitals/update.sh`**

Write `packages/kvitals/update.sh` with exactly this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

nix run github:Mic92/nix-update/1.13.1 -- \
  --flake --override-filename packages/kvitals/default.nix kvitals
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x packages/kvitals/update.sh`
Expected: exit 0.

Run: `test -x packages/kvitals/update.sh && echo OK`
Expected: prints `OK`.

- [ ] **Step 3: Dry-run the updater to confirm it resolves cleanly**

Run: `./packages/kvitals/update.sh`
Expected: exit 0. Because the derivation is already at the latest release
(v2.8.1), `git status --porcelain packages/kvitals/default.nix` should show no
change.

Run: `git status --porcelain packages/kvitals/default.nix`
Expected: empty output (no diff). If it produced a change, inspect it — it should
only ever be a legitimate version/hash bump, not a breakage.

- [ ] **Step 4: Commit**

```bash
git add packages/kvitals/update.sh
git commit -m "kvitals: add nix-update auto-update script"
```

---

## Task 3: Wire kvitals into the scheduled updater loop

**Files:**
- Modify: `.github/workflows/update.yml` (the "Run package updaters" step)

- [ ] **Step 1: Edit the updater loop**

In `.github/workflows/update.yml`, find the "Run package updaters" step. Replace
these two lines:

```yaml
          # kvitals has no updater
          for pkg in claude-code holmesgpt kagi-cli openshift slumber; do
```

with this single line (comment removed, `kvitals` added in alphabetical-ish
position after `kagi-cli`):

```yaml
          for pkg in claude-code holmesgpt kagi-cli kvitals openshift slumber; do
```

- [ ] **Step 2: Verify the change**

Run: `grep -n 'for pkg in' .github/workflows/update.yml`
Expected: shows the line including `kvitals`, e.g.
`for pkg in claude-code holmesgpt kagi-cli kvitals openshift slumber; do`

Run: `grep -c 'kvitals has no updater' .github/workflows/update.yml`
Expected: prints `0` (stale comment removed).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/update.yml
git commit -m "ci: add kvitals to scheduled updater loop"
```

---

## Task 4: Push branch and open PR

**Files:** none (git/GitHub operations only)

- [ ] **Step 1: Confirm the branch is ready**

Run: `git status -sb && git log --oneline origin/main..HEAD`
Expected: working tree clean; the log shows the spec, plan, and three
implementation commits (default.nix, update.sh, CI loop).

- [ ] **Step 2: Push the branch**

Run: `git push -u origin kvitals-v2-autoupdate`
Expected: branch published, exit 0.

- [ ] **Step 3: Open the PR**

```bash
gh pr create --base main --head kvitals-v2-autoupdate \
  --title "kvitals: repackage for v2.x and enable auto-update" \
  --body "$(cat <<'EOF'
## What

- Repackage `kvitals` for its rewritten v2.x layout (native KSysGuard sensors,
  no shell script). Drops `makeWrapper` and the runtime deps
  (`coreutils gawk procps iproute2 bc lm_sensors`); installs `metadata.json` +
  `contents/` only.
- Bump 1.3.0 → 2.8.1.
- Add `packages/kvitals/update.sh` (nix-update) and add `kvitals` to the
  scheduled updater loop in `.github/workflows/update.yml`.

## Why

The old derivation wrapped `contents/scripts/sys-stats.sh`, which upstream
deleted in the v2 rewrite, so kvitals could never auto-update without breaking
the build. See `docs/superpowers/specs/2026-06-10-kvitals-v2-autoupdate-design.md`.

## Verification

- `nix build .#kvitals` passes; build output contains the v2.8.1 plasmoid.
- `./packages/kvitals/update.sh` resolves to v2.8.1 with a no-op diff.
- Runtime functional check (widget loads, sensors populate) is manual on a
  NixOS Plasma 6.6 machine — not verified in CI (this flake has no CI builds).
EOF
)"
```
Expected: prints the new PR URL.

- [ ] **Step 4: Report the PR URL to the user.**

---

## Final verification

- [ ] **Build still green:** `nix build .#kvitals` → PASS.
- [ ] **Updater present and executable:** `test -x packages/kvitals/update.sh && echo OK` → `OK`.
- [ ] **CI loop includes kvitals:** `grep 'for pkg in' .github/workflows/update.yml` shows `kvitals`.

## Manual (user, post-merge)

A Plasma widget cannot be exercised headless. On the NixOS Plasma 6.6 machine,
after pulling the change, confirm the widget loads in the panel and its sensors
populate (CPU/RAM/Temp/Network values appear). This is the runtime functional
gate and is **not** claimed as verified by the implementer.
