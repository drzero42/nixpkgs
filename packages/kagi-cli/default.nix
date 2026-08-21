{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.17.2";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-C1bTEpbOj7afFyZCo/zXVCqifmlxZXzOxmg2eNOkA0w=";
  };

  cargoHash = "sha256-uQqQY9umaFUm9X3cOb8bgJiessrzyq92y0kYiTzDGyk=";

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
