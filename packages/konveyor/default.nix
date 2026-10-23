# A KWin plugin must be built against the consumer's exact KWin/Qt, so
# consumers callPackage this file against their own pkgs (konveyor-widgets
# comes from the overlay):
#
#   pkgs.kdePackages.callPackage "${inputs.drzero42-nixpkgs}/packages/konveyor" { }
#
# flake.nix registers it only so CI builds it; the overlay and the cachix
# push leave it out, since nobody could use that build.
#
# The System Monitor, Process Monitor and System Log widgets live in
# konveyor-widgets; this package has the rest (KWin effect and telemetry
# plugin, Kontrol Panel, taskbar, portals, monitor overlay).
{
  lib,
  stdenv,
  callPackage,
  konveyor-widgets,
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
  # nvidia-ml-py (pynvml): NVIDIA GPU stats; the widgets skip it without one.
  python = python3.withPackages (ps: [
    ps.dbus-python
    ps.nvidia-ml-py
  ]);

  # Commands widgets/install.sh `link_command`s into ~/.local/bin, relative to the widget tree.
  widgetCommands = [
    "router-monitor/bin/routermon-collect"
    "router-monitor/bin/routermon-ctl"
    "router-monitor/bin/routermon-config"
    "router-monitor/bin/routermon-speedtest"
    "portals/bin/portal-games"
    "portals/bin/portal-packages"
    "portals/bin/portal-launcher"
    "portals/bin/portal-friends"
    "service/monitor-overlay"
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

  source = callPackage ./source.nix { };

  # In konveyor-widgets, installed separately.
  widgetPlasmoids = [
    "org.devl0rd.sysmon"
    "org.devl0rd.sysmon.panel"
    "org.devl0rd.procmon"
    "org.devl0rd.procmon.panel"
    "org.devl0rd.logmon.journal"
  ];
in
stdenv.mkDerivation {
  pname = "konveyor";
  inherit (source) version src;

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
    # The monitor overlays reuse the panel widgets' UI, which calls their collectors.
    for c in sysmon-collect procmon-collect; do
      grep -rlF "\$HOME/.local/bin/$c" widgets --include='*.qml' | while read -r f; do
        substituteInPlace "$f" --replace-fail "\$HOME/.local/bin/$c" "${konveyor-widgets}/bin/$c"
      done
    done
    grep -rlF '$HOME/.local/bin/' widgets --include='*.qml' | while read -r f; do
      substituteInPlace "$f" --replace-fail '$HOME/.local/bin/' "$out/bin/"
    done
    # The default config is copied into ~/.config, so no store path there.
    substituteInPlace data/default-config.kdl --replace-fail '$HOME/.local/bin/' ""
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
    rm -r ${lib.concatMapStringsSep " " (id: "$out/share/plasma/plasmoids/${id}") widgetPlasmoids}

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
