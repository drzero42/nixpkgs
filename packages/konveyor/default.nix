# Not registered in flake.nix on purpose: a KWin plugin must be built against
# the consumer's exact KWin/Qt, so consumers callPackage this file against
# their own pkgs. Keeps it out of CI/cachix and the overlay.
#
#   pkgs.kdePackages.callPackage "${inputs.drzero42-nixpkgs}/packages/konveyor" { }
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  libxkbcommon,
  makeWrapper,
  kdePackages,
  libepoxy,
  libxcb,
  xcbutilwm,
  python3,
  jq,
  curl,
  openssh,
  systemd,
  glib,
}:

let
  # dbus-python: konveyor-cheatsheet and process-monitor's frame telemetry.
  # pynvml (NVIDIA GPU stats) is optional upstream and left out.
  python = python3.withPackages (ps: [ ps.dbus-python ]);

  # Commands widgets/install.sh `link_command`s into ~/.local/bin, relative to the widget tree.
  widgetCommands = [
    "system-monitor/bin/sysmon-collect"
    "process-monitor/bin/procmon-collect"
    "router-monitor/bin/routermon-collect"
    "router-monitor/bin/routermon-ctl"
    "router-monitor/bin/routermon-config"
    "router-monitor/bin/routermon-speedtest"
    "system-log/bin/logmon-collect"
    "portals/bin/portal-games"
    "portals/bin/portal-packages"
    "portals/bin/portal-launcher"
    "portals/bin/portal-friends"
    "service/monitor-overlay"
    "service/konveyor-widgets"
    "screen-rotate/bin/linux-plasma-screen-rotate"
  ];

  # Tools the widget scripts shell out to (widgets/install.sh `check_commands`).
  widgetPath = lib.makeBinPath [
    python
    jq
    curl
    openssh
    systemd
    glib
    kdePackages.libkscreen
    kdePackages.kpackage
    kdePackages.kconfig
    kdePackages.kglobalacceld
  ];
in
stdenv.mkDerivation {
  pname = "konveyor";
  version = "0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "63e0037c6fbdbfe27bc8af17c914543b5a779ed0";
    fetchSubmodules = true;
    hash = "sha256-b/fgn2S5hupGvAP6M3bt1FUiO8pHxs355r+e7MJtrrA=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    makeWrapper
    jq
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = [
    kdePackages.qtbase
    kdePackages.qtdeclarative
    kdePackages.kwin
    kdePackages.kdecoration
    kdePackages.kcoreaddons
    kdePackages.kglobalaccel
    kdePackages.kconfig
    kdePackages.kcolorscheme
    kdePackages.knotifications
    kdePackages.ki18n
    kdePackages.kcmutils
    kdePackages.kwindowsystem
    kdePackages.libplasma
    kdePackages.kirigami
    kdePackages.kirigami-addons
    kdePackages.layer-shell-qt
    libepoxy
    libxkbcommon
    libxcb
    xcbutilwm
    python
  ];

  cmakeFlags = [ "-DKONVEYOR_BUILD_TESTS=OFF" ];

  # Upstream installs widget tools to ~/.local/bin; point every caller at $out/bin.
  postPatch = ''
    substituteInPlace src/core/tools/widgettool.cpp \
      --replace-fail 'QDir::home().filePath(QStringLiteral(".local/bin/") + name)' \
                     "QStringLiteral(\"$out/bin/\") + name"
    substituteInPlace widgets/portals/shared/launcher/LauncherData.qml \
      --replace-fail 'PATH=\"$HOME/.local/bin:$PATH\" konveyor-cheatsheet' "$out/bin/konveyor-cheatsheet"
    substituteInPlace widgets/screen-rotate/plasmoid/contents/ui/main.qml \
      --replace-fail 'String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace("file://", "") + "/.local/bin/linux-plasma-screen-rotate"' \
                     "\"$out/bin/linux-plasma-screen-rotate\""
    grep -rlF '$HOME/.local/bin/' widgets data --include='*.qml' --include='*.kdl' | while read -r f; do
      substituteInPlace "$f" --replace-fail '$HOME/.local/bin/' "$out/bin/"
    done
    substituteInPlace widgets/process-monitor/bin/procmon_icons.py \
      --replace-fail '"/usr/share/applications",' \
                     '"/run/current-system/sw/share/applications", "/etc/profiles/per-user/" + os.environ.get("USER", "") + "/share/applications", "/usr/share/applications",'
  '';

  # Reproduce widgets/install.sh staging with upstream's own lib.sh helpers,
  # installing plasmoids into share/ instead of via kpackagetool6.
  postInstall = ''
    WIDGETS_DIR=$out/share/konveyor/widgets
    mkdir -p "$WIDGETS_DIR" $out/share/plasma/plasmoids
    cp -a ../widgets/. "$WIDGETS_DIR/" # cwd is the cmake build dir; ../widgets is the patched source
    find "$WIDGETS_DIR" -name .git -prune -exec rm -rf {} +

    say() { echo "$@"; }
    source "$WIDGETS_DIR/lib.sh"
    install_plasmoid() {
      local id
      id=$(jq -r .KPlugin.Id "$1/metadata.json")
      cp -a "$1" "$out/share/plasma/plasmoids/$id"
    }
    stage_kontrol_panel
    install_plasmoids

    ${lib.concatMapStrings (c: ''
      chmod +x "$WIDGETS_DIR/${c}"
      makeWrapper "$WIDGETS_DIR/${c}" "$out/bin/${baseNameOf c}" --prefix PATH : "$out/bin:${widgetPath}"
    '') widgetCommands}
  '';

  meta = {
    description = "Scrolling column tiling for KDE Plasma";
    homepage = "https://github.com/DevL0rd/Konveyor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
