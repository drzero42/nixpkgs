{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kvitals";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "yassine20011";
    repo = "kvitals";
    rev = "v${finalAttrs.version}";
    hash = "sha256-yhO+E/emv7T/pk0/CgbiNJuhHP326KHzJ9aVqZEcSKI=";
  };

  installPhase = ''
    runHook preInstall

    plasmoidDir=$out/share/plasma/plasmoids/org.kde.plasma.kvitals
    mkdir -p $plasmoidDir
    cp metadata.json $plasmoidDir/
    cp -r contents $plasmoidDir/

    runHook postInstall
  '';

  meta = {
    description = "Live system vitals in the KDE Plasma panel: CPU, RAM, Temp, Battery, Network";
    homepage = "https://github.com/yassine20011/kvitals";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
