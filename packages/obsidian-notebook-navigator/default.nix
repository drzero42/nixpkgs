{
  lib,
  stdenvNoCC,
  fetchurl,
  jq,
}:

# Notebook Navigator, laid out as an Obsidian community plugin directory
# (main.js, manifest.json, styles.css at the top level), the shape Home
# Manager's programs.obsidian communityPlugins expects. Upstream's release
# assets are the built plugin, so they're used as-is.
let
  version = "3.5.3";
  manifestId = "notebook-navigator";

  # One hash per release asset. update.sh rewrites these lines.
  hashes = {
    "main.js" = "sha256-yFVPsT/439MmiWmkm68+02+kMBV3hXjxRqyg7uy7jn4=";
    "manifest.json" = "sha256-w+pt8039cIPwl6Y4BdrPFD4A8mh7OglJ253Rq0uUYX8=";
    "styles.css" = "sha256-/RIzKRNAOjJz0DAdIFSHTSRarGArmwsVdqmPt3kOr1Y=";
  };

  fetchAsset =
    name: hash:
    fetchurl {
      url = "https://github.com/johansan/notebook-navigator/releases/download/${version}/${name}";
      inherit name hash;
    };
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-notebook-navigator";
  inherit version;

  srcs = lib.mapAttrsToList fetchAsset hashes;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    for src in $srcs; do
      cp $src $out/$(stripHash $src)
    done

    runHook postInstall
  '';

  # Fail the build if the assets aren't the pinned release of this plugin.
  doInstallCheck = true;
  nativeInstallCheckInputs = [ jq ];
  installCheckPhase = ''
    runHook preInstallCheck

    jq -e --arg id ${manifestId} --arg v ${version} '.id == $id and .version == $v' $out/manifest.json

    runHook postInstallCheck
  '';

  passthru = {
    # Home Manager names the plugin dir by this, and otherwise reads
    # manifest.json at eval time (import-from-derivation).
    inherit manifestId;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Notebook Navigator community plugin for Obsidian (alternative file and tag navigator)";
    homepage = "https://github.com/johansan/notebook-navigator";
    changelog = "https://github.com/johansan/notebook-navigator/releases/tag/${version}";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
  };
}
