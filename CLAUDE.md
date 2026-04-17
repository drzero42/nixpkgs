# CLAUDE.md

## Purpose

Public Nix flake exposing a small overlay of packages: `anytype`, `anytype-heart`, `claude-code`, `holmesgpt`, `kagi-cli`, `kvitals`. Consumed as a flake input; auto-updated every six hours by GitHub Actions.

## Layout

```
nixpkgs/
├── flake.nix                   # flake-parts entry point
├── overlay.nix                 # nixpkgs overlay
├── README.md
├── LICENSE
├── CLAUDE.md
├── .envrc                      # direnv → devenv
├── devenv.{nix,yaml}           # dev shell
├── .claude/settings.json       # enables nixd LSP
├── packages/<name>/
│   ├── default.nix             # package derivation
│   ├── update.sh               # (optional) auto-update script
│   └── ...                     # patches, lockfiles, etc.
└── .github/workflows/update.yml
```

## Code-Exploration Policy

Always use jCodemunch MCP tools — never fall back to Read, Grep, Glob, or Bash for code exploration.

- Before reading a file: `get_file_outline` or `get_file_content`
- Before searching: `search_symbols` or `search_text`
- Before exploring structure: `get_file_tree` or `get_repo_outline`
- Call `list_repos` first; if this repo is not indexed, call `index_folder` with the current directory.
- Markdown/docs: use jdocmunch MCP (`mcp__jdocmunch__list_repos`, `mcp__jdocmunch__index_local`).

## Adding a new package

1. `mkdir packages/<name>/` and write `packages/<name>/default.nix` — a standard callPackage-shaped function.
2. If upstream is trackable, add `packages/<name>/update.sh`:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   nix run github:Mic92/nix-update/1.13.1 -- \
     --flake --override-filename packages/<name>/default.nix <name>
   ```

   Make it executable: `chmod +x packages/<name>/update.sh`.
3. Register in `flake.nix` under `perSystem.packages`:

   ```nix
   <name> = pkgs.callPackage ./packages/<name> {};
   ```

4. Register in `overlay.nix`:

   ```nix
   <name> = prev.callPackage ./packages/<name> {};
   ```

5. If the package has an updater, add it to the loop in `.github/workflows/update.yml`.
6. Audit `meta.platforms` in `default.nix` so unsupported systems fail at eval, not build.
7. `git add packages/<name>/ flake.nix overlay.nix`, run `nix build .#<name>`, commit.

## Updating manually

```bash
./packages/<name>/update.sh
nix build .#<name>
```

## Formatting

`nix fmt` — uses `nixfmt-rfc-style` via devenv.

## Devshell

`direnv allow` activates automatically on entering the directory. Provides `nixfmt-rfc-style`, `nix-update`, `jq`, `curl`.

## CI Behavior

Scheduled workflow runs at 00:17, 06:17, 12:17, 18:17 UTC. It invokes every package's `update.sh`, runs `nix flake update`, and — if anything changed — commits directly to `main` as `github-actions[bot]`. **There are no CI builds.** Downstream consumers (e.g. nix-config) detect breakage at build time.

Individual updater failures do not block the run; they are logged as GitHub warnings while other updaters proceed.

Manual trigger: Actions tab → "Scheduled update" → Run workflow.

## Gotchas

- Use `nix hash convert --to sri --hash-algo sha256 <base32>` — the older `nix hash to-sri` is deprecated.
- `nix-update`'s `--override-filename` path is relative to the repo root, e.g. `packages/anytype/default.nix`.
- `holmesgpt` uses `poetry2nix`. If a new package also needs it, pull `poetry2nix` from the flake input already wired in `flake.nix` (it's exposed in `perSystem` as the `poetry2nix` let-binding; pass `mkPoetryApplication`/`defaultPoetryOverrides` explicitly to `callPackage`).
- Set `meta.platforms` on each package — the flake advertises four systems but some packages (e.g. `anytype`) are linux-only.
