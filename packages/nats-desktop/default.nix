{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  pkg-config,
  patchelf,
  wayland,
  libxkbcommon,
  libGL,
  vulkan-headers,
  vulkan-loader,
  libx11,
  libxcursor,
  libxfixes,
  libxcb,
  gtk3,
}:

buildGoModule (finalAttrs: {
  pname = "nats-desktop";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "thedataflows";
    repo = "nats-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-b9JPfgZUiPdIBs8mTyKmtPlGut9RxqxFmKn5if66mYY=";
  };

  vendorHash = null;

  subPackages = [ "cmd/nats-desktop" ];

  nativeBuildInputs = [
    pkg-config
    patchelf
    copyDesktopItems
  ];

  buildInputs = [
    wayland
    libxkbcommon
    libGL
    vulkan-headers
    vulkan-loader
    libx11
    libxcursor
    libxfixes
    libxcb
    gtk3
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "nats-desktop";
      desktopName = "NATS Desktop";
      exec = "nats-desktop";
      icon = "nats-desktop";
      comment = "Cross-platform desktop GUI for NATS";
      categories = [
        "Development"
        "Network"
      ];
    })
  ];

  postInstall = ''
    for size in 32 64 128 256 512; do
      install -Dm644 assets/icons/nats-plain-''${size}px.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/nats-desktop.png
    done
  '';

  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath finalAttrs.buildInputs} $out/bin/nats-desktop
  '';

  meta = {
    description = "Cross-platform desktop GUI for NATS";
    homepage = "https://github.com/thedataflows/nats-desktop";
    license = lib.licenses.mit;
    mainProgram = "nats-desktop";
    platforms = [ "x86_64-linux" ];
  };
})
