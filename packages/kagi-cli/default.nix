{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-KlZBZpnza9SYbHvCYhJu3ivv5fh5r77wL4Tz6vXZe7A=";
  };

  cargoHash = "sha256-gJqndpFeXCBBRTEToFV5tPgJHIxb7o6Uc3KNNxzFe1k=";

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
