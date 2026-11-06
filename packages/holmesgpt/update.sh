#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
PKG_DIR=packages/holmesgpt

NIX_UPDATE_VERSION=$(cat packages/.nix-update-version)
nix run "github:Mic92/nix-update/${NIX_UPDATE_VERSION}" -- \
  --flake --override-filename "$PKG_DIR/default.nix" holmesgpt

# Upstream uses Poetry; regenerate the vendored uv.lock that uv2nix consumes,
# constrained to the versions in upstream's poetry.lock.
SRC=$(nix build --no-link --print-out-paths .#holmesgpt.src)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -r --no-preserve=mode "$SRC/." "$WORK"
# migrate-to-uv pins every poetry.lock entry for all Python versions, so a
# package locked twice with per-Python markers (filelock 3.x for <3.11, 4.x for
# >=3.11) becomes an unsatisfiable ==A and ==B. We only build with python313
# (see default.nix), so narrow the Python range to it and keep only the last
# (poetry sorts ascending, so newest) lock entry per package.
nix shell nixpkgs#python313 -c python3 -I - "$WORK" <<'EOF'
import re, sys
work = sys.argv[1]
toml = f"{work}/pyproject.toml"
text, n = re.subn(r'^python = ".*"$', 'python = ">=3.13,<3.14"', open(toml).read(), count=1, flags=re.M)
assert n == 1, "no poetry python constraint in pyproject.toml"
open(toml, "w").write(text)
lock = f"{work}/poetry.lock"
head, *pkgs = open(lock).read().split("\n[[package]]\n")
name = lambda p: re.search(r'^name = "(.*)"$', p, re.M).group(1)
last = {name(p): i for i, p in enumerate(pkgs)}
keep = [p for i, p in enumerate(pkgs) if last[name(p)] == i]
open(lock, "w").write("\n[[package]]\n".join([head, *keep]))
EOF
nix shell nixpkgs#migrate-to-uv nixpkgs#uv nixpkgs#python313 -c \
  migrate-to-uv --skip-uv-checks --keep-current-build-backend "$WORK"
cp "$WORK/pyproject.toml" "$WORK/uv.lock" "$PKG_DIR/"
