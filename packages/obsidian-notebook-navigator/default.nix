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
  version = "3.5.1";
  manifestId = "notebook-navigator";

  # One hash per release asset. update.sh rewrites these lines.
  hashes = {
    "main.js" = "sha256-ZN4F8vDOySJZeZVvFzoUQ+PwQZdLfXhF/YG7+XKhPww=";
    "manifest.json" = "sha256-pOKwNYvoMd7E4dZit7u/domDKEkWSMm76TNR0V3jPLA=";
    "styles.css" = "sha256-DueMhPuUPLwkaziEZKqknXzx7I5Gm+Dao7ndqKOPQW8=";
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
