{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-amzljri511xixUZPISwnjtlPkSFaOfzGonR307MZK3A=";
  };

  cargoHash = "sha256-hrE8X9710NknO5fyDJdJxREVplB2zb9rWhn8VWt1btc=";

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
