{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-wQ0HuA8+4A4s6HNbl5SNWOQcTcGBkYzmB/aXXhY8bUk=";
  };

  cargoHash = "sha256-r2S6BSo6xBMeg5psyzXqaPlQKlC1Y3Jfibb5mDgcTgI=";

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
