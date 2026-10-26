# A KWin plugin must be built against the consumer's exact KWin/Qt, so
# consumers callPackage this file against their own pkgs:
#
#   pkgs.kdePackages.callPackage "${inputs.drzero42-nixpkgs}/packages/konveyor" { }
#
# flake.nix registers it only so CI builds it; the overlay and the cachix
# push leave it out, since nobody could use that build.
#
# The System Monitor and System Log widgets live in konveyor-widgets (Process
# Monitor's panel widgets ship in neither); this package has the rest (KWin effect and telemetry
# plugin, Kontrol Panel, taskbar, portals, monitor overlay).
{
  lib,
  stdenv,
  callPackage,
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
  git,
  nodejs,
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

  # In konveyor-widgets, installed separately, or (Process Monitor) not shipped.
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

  # Upstream builds with warnings as errors; a newer compiler than upstream's
  # shouldn't fail the package over a new warning.
  cmakeFlags = [ "--compile-no-warning-as-error" ];

  # The tests run upstream's scripts directly.
  postPatch = ''
    patchShebangs widgets tests extras tools install.sh uninstall.sh
  '';

  doCheck = true;
  nativeCheckInputs = [
    git
    nodejs
  ];
  # The QML modules the widget and settings tests import, as other Qt packages
  # in nixpkgs set them up for their checks. The nested tests need a running
  # KWin session, so only the unit-labelled tests run.
  preCheck = ''
    export HOME=$(mktemp -d) XDG_RUNTIME_DIR=$(mktemp -d)
    export XDG_DATA_DIRS=${
      lib.makeSearchPath "share" [
        kdePackages.breeze
        kdePackages.libplasma
      ]
    }
    export QT_PLUGIN_PATH=${
      lib.makeSearchPath kdePackages.qtbase.qtPluginPrefix [
        (lib.getBin kdePackages.qtbase)
        kdePackages.qtsvg
        # Kirigami's Plasma and desktop styles, which give the panels their colours.
        kdePackages.libplasma
        kdePackages.qqc2-desktop-style
      ]
    }
    export QML2_IMPORT_PATH=${
      lib.makeSearchPath kdePackages.qtbase.qtQmlPrefix (
        map lib.getBin (
          with kdePackages;
          [
            qtdeclarative
            qt5compat
            # kirigami is a wrapper propagating these two; it has no QML of its own.
            kirigami.unwrapped
            qqc2-desktop-style
            kirigami-addons
            libplasma
            ksvg
            kdeclarative
            kiconthemes
            kcmutils
            layer-shell-qt
            kcoreaddons
            ki18n
          ]
        )
        # org.kde.plasma.private.kicker lives in the main output.
        ++ [ kdePackages.plasma-workspace ]
      )
    }
  '';
  # The launcher's apps and rows tests watch KDE's app database refresh and list
  # KIO's Network place, which need a live session's D-Bus services. ctest can
  # only skip whole test programs, so their other cases are skipped with them.
  checkPhase = ''
    runHook preCheck
    ctest -L unit -E '^test_launcher_(apps|rows)_qml$'
    runHook postCheck
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
