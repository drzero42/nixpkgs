{
  lib,
  callPackage,
  makeWrapper,
  python313,
  runCommand,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:

let
  # pyproject.toml pins unifi-network-mcp from PyPI and uv.lock locks its
  # dependency tree; update.sh bumps both. The PyPI wheels keep upstream's
  # exact pins (e.g. aiounifi==95) instead of nixpkgs' python package set.
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  lockedVersion =
    (lib.findFirst (
      p: p.name == "unifi-network-mcp"
    ) (throw "unifi-network-mcp missing from uv.lock") (lib.importTOML ./uv.lock).package).version;

  pythonSet = (callPackage pyproject-nix.build.packages { python = python313; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
    ]
  );

  venv = pythonSet.mkVirtualEnv "unifi-network-mcp-env" workspace.deps.default;
in
runCommand "unifi-network-mcp-${lockedVersion}"
  {
    version = lockedVersion;
    nativeBuildInputs = [ makeWrapper ];
    passthru = {
      inherit venv;
      updateScript = ./update.sh;
    };
    meta = {
      description = "MCP server for the UniFi Network application";
      homepage = "https://github.com/sirkirby/unifi-mcp";
      changelog = "https://github.com/sirkirby/unifi-mcp/releases/tag/network/v${lockedVersion}";
      license = lib.licenses.mit;
      maintainers = [ ];
      mainProgram = "unifi-network-mcp";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
  ''
    makeWrapper ${venv}/bin/unifi-network-mcp $out/bin/unifi-network-mcp
  ''
