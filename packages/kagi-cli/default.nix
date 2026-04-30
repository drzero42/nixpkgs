{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-3iP3/8l3S5dcDVv938BK9VFKMgWzu/Q6k4obGvtmd2s=";
  };

  cargoHash = "sha256-olMPC1ODtIJxmwur1xphYKtQvbJMRWtHlRRBbQRcvuM=";

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
