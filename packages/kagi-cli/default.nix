{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.4.7";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-TXyaJLEqo/7uCTPC/iHGoXt3MgBtn276ujNPDXYUtfY=";
  };

  cargoHash = "sha256-+Zjj9h9yGiFhCs1sbj8IP3mCAiYG0kNtn/IBBiNTx1A=";

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
