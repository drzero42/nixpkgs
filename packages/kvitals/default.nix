{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  coreutils,
  gawk,
  procps,
  iproute2,
  bc,
  lm_sensors,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kvitals";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "yassine20011";
    repo = "kvitals";
    rev = "v${version}";
    hash = "sha256-qJX/W2Zp5g7IlImXTLfBr8WKMrNOtfPPVqja7JhwRMw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    plasmoidDir=$out/share/plasma/plasmoids/org.kde.plasma.kvitals
    mkdir -p $plasmoidDir
    cp metadata.json $plasmoidDir/
    cp -r contents $plasmoidDir/

    wrapProgram $plasmoidDir/contents/scripts/sys-stats.sh \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        gawk
        procps
        iproute2
        bc
        lm_sensors
      ]}

    runHook postInstall
  '';

  meta = {
    description = "Live system vitals in the KDE Plasma panel: CPU, RAM, Temp, Battery, Network";
    homepage = "https://github.com/yassine20011/kvitals";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
