{
  lib,
  stdenvNoCC,
  callPackage,
  fetchFromGitHub,
}:

# OpenCode v2 is tagged on upstream's dev branch (no GitHub Releases), and
# upstream maintains its own derivation plus per-system node_modules hashes
# (nix/hashes.json). Build with that instead of duplicating it here.
let
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-7vw0TcaFsMN+XbZoU1gwHE1r8ppPPK0CTQqPbVQozT8=";
  };

  # A tag's nix/hashes.json is usually stale: upstream's bot refreshes it on
  # dev only after tagging. update.sh computes x86_64-linux's hash instead.
  # ponytail: other systems still take hashes.json; CI only builds x86_64-linux.
  nodeModulesHash = "sha256-PYcpyYP/i0e6ZIt27u1tFYbjU4Cl848w77dU1NiIEls=";
  node_modules = callPackage "${src}/nix/node_modules.nix" (
    {
      rev = "nix";
    }
    // lib.optionalAttrs (stdenvNoCC.hostPlatform.system == "x86_64-linux") { hash = nodeModulesHash; }
  );
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
