{
  lib,
  callPackage,
  fetchFromGitHub,
}:

# OpenCode v2 is tagged on upstream's dev branch (no GitHub Releases), and
# upstream maintains its own derivation plus per-system node_modules hashes
# (nix/hashes.json). Build with that instead of duplicating it here.
let
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-Q26ABM+QF6PAjMSCSdp/ThjCazSJvJUJwP66Y31gzy0=";
  };

  # ponytail: hashes.json is computed against upstream's nixpkgs bun; if ours
  # drifts far enough to change node_modules, pass `hash` here and track it.
  node_modules = callPackage "${src}/nix/node_modules.nix" { rev = "nix"; };
in
(callPackage "${src}/nix/opencode.nix" { inherit node_modules; }).overrideAttrs (old: {
  inherit version;
  # upstream derives version from package.json + rev; src is unchanged
  __intentionallyOverridingVersion = true;

  postInstall = old.postInstall + ''
    wrapProgram $out/bin/opencode --set OPENCODE_DISABLE_AUTOUPDATE true
  '';

  passthru = old.passthru // {
    updateScript = ./update.sh;
    # Full upstream tree (src above is filtered and lacks nix/), for opencode-desktop.
    upstreamSrc = src;
  };

  meta = old.meta // {
    homepage = "https://github.com/anomalyco/opencode";
    changelog = "https://github.com/anomalyco/opencode/tree/v${version}";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
