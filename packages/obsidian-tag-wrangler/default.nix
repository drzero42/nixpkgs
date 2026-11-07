{
  lib,
  stdenvNoCC,
  fetchurl,
  jq,
}:

# Tag Wrangler, laid out as an Obsidian community plugin directory
# (main.js and manifest.json at the top level), the shape Home
# Manager's programs.obsidian communityPlugins expects. Upstream's release
# assets are the built plugin, so they're used as-is.
let
  version = "0.6.5";
  manifestId = "tag-wrangler";

  # One hash per release asset. update.sh rewrites these lines.
  hashes = {
    "main.js" = "sha256-85C/E1E1AzyyuEhUOK9C77mT3dkyVawINgFuES7pqyA=";
    "manifest.json" = "sha256-JxqT5gWwn2iftLBa8fc/UIDgh2/CR2NeT+niwtiK2pY=";
  };

  fetchAsset =
    name: hash:
    fetchurl {
      url = "https://github.com/pjeby/tag-wrangler/releases/download/${version}/${name}";
      inherit name hash;
    };
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-tag-wrangler";
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
    description = "Tag Wrangler community plugin for Obsidian (rename, merge and search tags)";
    homepage = "https://github.com/pjeby/tag-wrangler";
    changelog = "https://github.com/pjeby/tag-wrangler/releases/tag/${version}";
    license = lib.licenses.isc;
    platforms = lib.platforms.all;
  };
}
