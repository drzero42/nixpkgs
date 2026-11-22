{
  lib,
  stdenvNoCC,
  fetchurl,
  jq,
}:

# Self-hosted LiveSync, laid out as an Obsidian community plugin directory
# (main.js, manifest.json, styles.css at the top level), the shape Home
# Manager's programs.obsidian communityPlugins expects. Upstream's release
# assets are the built plugin, so they're used as-is.
let
  version = "1.0.52";
  manifestId = "obsidian-livesync";

  # One hash per release asset. update.sh rewrites these lines.
  hashes = {
    "main.js" = "sha256-B6JWyrrD0tFkN6AWLSniGe35chasP7KBhTGlBbxmY/M=";
    "manifest.json" = "sha256-w9Y0ivDgd7r3rSPvJ8bIltPnFggb1TD+c0vvoS+f9aE=";
    "styles.css" = "sha256-71/zHUD8fIL0Tah3sPYaSWHsnwVaFPI/8OWE/Wnv9P8=";
  };

  fetchAsset =
    name: hash:
    fetchurl {
      url = "https://github.com/vrtmrz/obsidian-livesync/releases/download/${version}/${name}";
      inherit name hash;
    };
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-livesync";
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
    description = "Self-hosted LiveSync community plugin for Obsidian (CouchDB sync)";
    homepage = "https://github.com/vrtmrz/obsidian-livesync";
    changelog = "https://github.com/vrtmrz/obsidian-livesync/releases/tag/${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
