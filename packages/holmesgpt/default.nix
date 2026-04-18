{
  lib,
  fetchFromGitHub,
  mkPoetryApplication,
  defaultPoetryOverrides,
  python312,
}:

let
  version = "0.24.3";
in
(mkPoetryApplication rec {
  pname = "holmesgpt";
  # Note: pyproject.toml has version = "0.0.0" (uses dynamic versioning)
  # We override the version attribute below to match the Git tag

  src = fetchFromGitHub {
    owner = "HolmesGPT";
    repo = pname;
    tag = version;
    hash = "sha256-3UBXI1N7yv0tnd2PXcoqrAlPpzYK3we/xtEKqf/6nMU=";
    # Remove wheel entries that poetry2nix doesn't support:
    # - riscv64: not supported by poetry2nix
    # - graalpy with complex ABI tags: parseABITag regex too restrictive
    postFetch = ''
      sed -i '/manylinux.*_riscv64/d' $out/poetry.lock
      sed -i '/musllinux.*_riscv64/d' $out/poetry.lock
      sed -i '/graalpy.*_.*_native/d' $out/poetry.lock
    '';
  };

  projectDir = src;

  python = python312;
  # Locked to python312: nixpkgs python311 currently has a broken pip→sphinx eval
  # (sphinx 9.x requires py>=3.12); python313+ poetry2nix overrides aren't ready yet.
  preferWheels = true;

  overrides = defaultPoetryOverrides.extend (final: prev: {
    # nixpkgs' python-modules/build and pyproject-hooks no longer accept
    # `tomli`, but poetry2nix's defaultPoetryOverrides still passes it.
    # Bypass the broken bootstrap overrides by using python312's directly.
    build = python312.pkgs.build;
    pyproject-hooks = python312.pkgs.pyproject-hooks;

    # types-typed-ast was removed from nixpkgs (typed-ast itself was removed)
    # It's just type stubs, not needed at runtime
    types-typed-ast = null;

    # cryptography needs rustPlatform.cargoSetupHook when built from source;
    # use the nixpkgs build directly to avoid poetry2nix's broken setup.
    cryptography = python312.pkgs.cryptography;

    # mkdocs-material: skip pyproject.toml patching for wheels
    mkdocs-material = prev.mkdocs-material.overridePythonAttrs (old: {
      postPatch = "";
    });

    # clickhouse-sqlalchemy: needs setuptools for build
    clickhouse-sqlalchemy = prev.clickhouse-sqlalchemy.overridePythonAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ final.setuptools ];
    });
  });

  meta = {
    description = "AI-powered SRE agent for incident response and troubleshooting";
    homepage = "https://github.com/HolmesGPT/holmesgpt";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "holmes";
    platforms = lib.platforms.linux;
  };

  passthru.updateScript = ./update.sh;
}).overrideAttrs (old: {
  # Override version from pyproject.toml (0.0.0) to match Git tag
  inherit version;
  __intentionallyOverridingVersion = true;
})
