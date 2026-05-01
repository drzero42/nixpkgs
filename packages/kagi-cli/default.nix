{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-/ig3NklSG/B748725jkNrAJggiUjFmdfuIwfOArtmIg=";
  };

  cargoHash = "sha256-mJRdCIvxPIkxuE3IoGWMav3aeNq3bpoS8lWM/VhBFpY=";

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
