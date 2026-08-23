{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.18.1";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-Wc33KLs9DR4IfKHrq1zqdC+LfhysN3OXYKNSb7p10rY=";
  };

  cargoHash = "sha256-W1SwFy0Tt1u/7fjQeYdj5sVACVQaaVQpdMFxZR1JpQU=";

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  # Upstream test bug: session_env helper omits KAGI_NEWS_BASE_URL, so this
  # test escapes the httpmock server and tries to reach news.kagi.com.
  checkFlags = [
    "--skip=mcp_tool_call_error_returns_json_rpc_error_and_keeps_server_alive"
  ];

  meta = {
    description = "Terminal CLI for Kagi search";
    homepage = "https://github.com/Microck/kagi-cli";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "kagi";
  };

  passthru.updateScript = ./update.sh;
}
