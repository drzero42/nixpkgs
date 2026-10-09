# AGENTS.md

## Purpose

Public Nix flake exposing a small overlay of packages; `perSystem.packages` in `flake.nix` is the list. Consumed as a flake input; auto-updated every six hours by GitHub Actions.

## Layout

```
nixpkgs/
├── flake.nix                   # flake-parts entry point
├── overlay.nix                 # nixpkgs overlay
├── README.md
├── LICENSE
├── AGENTS.md
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
2. If upstream is trackable, add `packages/<name>/update.sh` — mirror an existing one (e.g. `packages/slumber/`) and substitute the name. Read the pin from `packages/.nix-update-version`; don't hardcode the nix-update version. Then `chmod +x packages/<name>/update.sh`.
3. Register in `flake.nix` under `perSystem.packages`:

   ```nix
   <name> = pkgs.callPackage ./packages/<name> {};
   ```

   `overlay.nix` re-exports `perSystem.packages` as-is, so there's nothing to add there.
4. Audit `meta.platforms` in `default.nix` so unsupported systems fail at eval, not build.
5. `git add packages/<name>/ flake.nix`, run `nix build .#<name>`, commit.

## Updating manually

```bash
./packages/<name>/update.sh
nix build .#<name>
```

## Formatting

`nix fmt` — runs `nixfmt-tree` (the flake's `formatter`) over all tracked `.nix` files.

## Devshell

`direnv allow` activates automatically on entering the directory. Provides `nixfmt-rfc-style`, `nix-update`, `jq`, `curl`.

## CI Behavior

Scheduled workflow runs at 00:17, 06:17, 12:17, 18:17 UTC. It invokes every package's `update.sh`, runs `nix flake update`, and — if anything changed — commits directly to `main` as `github-actions[bot]`. `build.yml` then builds every `x86_64-linux` package and pushes it to drzero42.cachix.org.

A failed updater has its edits reverted while the others proceed; successful updates are still committed, then the run fails so the breakage is visible.

Manual trigger: Actions tab → "Scheduled update" → Run workflow.

## Gotchas

- Use `nix hash convert --to sri --hash-algo sha256 <base32>` — the older `nix hash to-sri` is deprecated.
- `nix-update`'s `--override-filename` path is relative to the repo root, e.g. `packages/claude-code/default.nix`.
- Set `meta.platforms` on each package — unsupported systems should fail at eval, not build.
- `holmesgpt` is built with uv2nix from a vendored `uv.lock` that `update.sh` generates from upstream's `poetry.lock` (via `migrate-to-uv`). If a new upstream release pulls in an sdist-only dependency that doesn't declare its build backend, the scheduled update still commits but the build fails (e.g. `ModuleNotFoundError: No module named 'setuptools'`). Fix: add an override next to the `clickhouse-sqlalchemy` one in `packages/holmesgpt/default.nix`, adding `final.resolveBuildSystem { setuptools = [ ]; }` (or whatever backend it needs) to `nativeBuildInputs`.

## Agent skills

### Issue tracker

GitHub Issues at `github.com/drzero42/nixpkgs` via the `gh` CLI. External PRs ARE a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary, no overrides. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
