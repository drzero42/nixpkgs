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
  version = "1.0.49";
  manifestId = "obsidian-livesync";

  # One hash per release asset. update.sh rewrites these lines.
  hashes = {
    "main.js" = "sha256-+Hlc2KC/KDPuRuP0ULx4j4rmBsbBsuByTYuMOjZKvPI=";
    "manifest.json" = "sha256-kz9Ki09v3zcc5FmAbFJalTJtyYXrNSv7lnLmhuh+S/s=";
    "styles.css" = "sha256-tq+dIUwI8AWD6z/jWikb7RmojJzk7553jC3wr7Pzq30=";
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
