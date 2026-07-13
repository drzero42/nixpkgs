{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kvitals";
  version = "2.11.0";

  src = fetchFromGitHub {
    owner = "yassine20011";
    repo = "kvitals";
    rev = "v${finalAttrs.version}";
    hash = "sha256-89SR9YR64dqEdM1FhUvN8SuMxaMsCdQdOafQ69LyMRY=";
  };

  installPhase = ''
    runHook preInstall

    plasmoidDir=$out/share/plasma/plasmoids/org.kde.plasma.kvitals
    mkdir -p $plasmoidDir
    cp metadata.json $plasmoidDir/
    cp -r contents $plasmoidDir/

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Live system vitals in the KDE Plasma panel: CPU, RAM, Temp, Battery, Network";
    homepage = "https://github.com/yassine20011/kvitals";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
