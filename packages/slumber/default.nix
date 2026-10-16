{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "slumber";
  version = "5.4.2";

  src = fetchFromGitHub {
    owner = "LucasPickering";
    repo = "slumber";
    tag = "v${finalAttrs.version}";
    hash = "sha256-695iw56rRYnCe3gSWzP7sJ9MYQWQOExym9spW4Dz7Hw=";
  };

  cargoHash = "sha256-IWKQePdIz9Pp4xf+75fLCGnoVdYtkBHWny/VX3TIi2I=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Terminal-based HTTP/REST client";
    homepage = "https://slumber.lucaspickering.me";
    changelog = "https://github.com/LucasPickering/slumber/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "slumber";
    maintainers = with lib.maintainers; [ javaes ];
  };
})
