{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "kagi-cli";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "Microck";
    repo = "kagi-cli";
    tag = "v${version}";
    hash = "sha256-fnoyXvgeSF+CgAfRtNjRS3kCh/0Ja6r7mYYOO/kPmkU=";
  };

  cargoHash = "sha256-fd64G8LLTxSAgjsGiOFp8UuOUcL01hUoe2asui/HUDQ=";

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
