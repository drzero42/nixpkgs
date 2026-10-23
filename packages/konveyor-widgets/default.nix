# Konveyor's System Monitor, Process Monitor and System Log widgets with their
# collectors. Plain QML and Python, so unlike konveyor it isn't tied to the
# consumer's KWin/Qt: one build serves any Plasma 6 desktop, with or without
# Konveyor (frame rates in Process Monitor need konveyor's KWin plugin).
{
  lib,
  stdenvNoCC,
  callPackage,
  makeWrapper,
  jq,
  python3,
  systemd,
}:

let
  source = callPackage ../konveyor/source.nix { };

  # dbus-python: Process Monitor's frame telemetry. nvidia-ml-py (pynvml):
  # NVIDIA GPU stats; the widgets skip them without one.
  python = python3.withPackages (ps: [
    ps.dbus-python
    ps.nvidia-ml-py
  ]);

  commands = [
    "system-monitor/bin/sysmon-collect"
    "process-monitor/bin/procmon-collect"
    "system-log/bin/logmon-collect"
    "service/konveyor-widgets"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "konveyor-widgets";
  inherit (source) version src;

  nativeBuildInputs = [
    makeWrapper
    jq
  ];

  dontConfigure = true;
  dontBuild = true;

  # Upstream installs the collectors to ~/.local/bin; point the widgets at $out/bin.
  # The collector supervisor runs only the collectors packaged here.
  postPatch = ''
    for f in widgets/system-monitor/plasmoids/org.devl0rd.sysmon.panel/contents/ui/main.qml \
             widgets/process-monitor/plasmoids/org.devl0rd.procmon.panel/contents/ui/main.qml; do
      substituteInPlace "$f" --replace-fail '$HOME/.local/bin/' "$out/bin/"
    done
    substituteInPlace widgets/process-monitor/bin/procmon_icons.py \
      --replace-fail '"/usr/share/applications",' \
                     '"/run/current-system/sw/share/applications", "/etc/profiles/per-user/" + os.environ.get("USER", "") + "/share/applications", "/usr/share/applications",'
    substituteInPlace widgets/service/konveyor-widgets \
      --replace-fail '    ("router-monitor", ["bin/routermon-collect", "--serve"], ["-S"]),' "" \
      --replace-fail '    ("portals", ["bin/portal-friends", "--serve"], []),' ""
  '';

  # Reproduce widgets/install.sh `install_plasmoids` for these widgets with
  # upstream's own lib.sh helpers, into share/ instead of via kpackagetool6.
  installPhase = ''
    runHook preInstall

    WIDGETS_DIR=$out/share/konveyor/widgets
    mkdir -p "$WIDGETS_DIR" $out/share/plasma/plasmoids
    cp -a widgets/lib.sh widgets/shared widgets/service \
      widgets/system-monitor widgets/process-monitor widgets/system-log "$WIDGETS_DIR/"

    say() { echo "$@"; }
    source "$WIDGETS_DIR/lib.sh"
    install_plasmoid() {
      cp -a "$1" "$out/share/plasma/plasmoids/$(jq -r .KPlugin.Id "$1/metadata.json")"
    }
    sysmon=$WIDGETS_DIR/system-monitor/plasmoids
    copy_panel_ui "$sysmon/org.devl0rd.sysmon.panel" "$sysmon/org.devl0rd.sysmon"
    procmon=$WIDGETS_DIR/process-monitor/plasmoids
    copy_panel_ui "$procmon/org.devl0rd.procmon.panel" "$procmon/org.devl0rd.procmon" proc.worker.mjs
    for plasmoid in "$sysmon"/org.devl0rd.sysmon{,.panel} "$procmon"/org.devl0rd.procmon{,.panel}; do
      stage_lib "$plasmoid"
      install_plasmoid "$plasmoid"
    done
    stage_lib "$WIDGETS_DIR/system-log/plasmoids/org.devl0rd.logmon.journal" "$WIDGETS_DIR/system-log/shared/lib"
    install_plasmoid "$WIDGETS_DIR/system-log/plasmoids/org.devl0rd.logmon.journal"

    ${lib.concatMapStrings (c: ''
      chmod +x "$WIDGETS_DIR/${c}"
      makeWrapper "$WIDGETS_DIR/${c}" "$out/bin/${baseNameOf c}" \
        --prefix PATH : "$out/bin:${
          lib.makeBinPath [
            python
            systemd
          ]
        }"
    '') commands}

    runHook postInstall
  '';

  meta = {
    description = "Konveyor's System Monitor, Process Monitor and System Log Plasma widgets";
    homepage = "https://github.com/DevL0rd/Konveyor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
