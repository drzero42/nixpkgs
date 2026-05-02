{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-KuVXzfAS57piTLEKxzWB8D1qNJSTHEVMvecXomYZDYA=";
  };

  cargoHash = "sha256-o/O/keSOvDFcm2UPHKxAvfFanVIu5pcAsAVk1ToKex8=";

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
