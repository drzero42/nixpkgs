{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-mftE3znjHkJcJ/KvAMocmiCZ8nGTpnPnH1ZtlOHK2vE=";
  };

  cargoHash = "sha256-Xg5RBGcCnSCQdgZOhB5ArHuLzFmN4qQwtl2NYndW2rs=";

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
