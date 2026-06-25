{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
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

  nativeBuildInputs = [ pkg-config ];

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

  meta = {
    description = "Cross-platform desktop GUI for NATS";
    homepage = "https://github.com/thedataflows/nats-desktop";
    license = lib.licenses.mit;
    mainProgram = "nats-desktop";
    platforms = [ "x86_64-linux" ];
  };
})
