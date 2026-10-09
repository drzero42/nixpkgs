{
  lib,
  bash,
  callPackage,
  fetchFromGitHub,
  kubectl,
  makeWrapper,
  python313,
  runCommand,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:

let
  version = "0.43.0";

  src = fetchFromGitHub {
    owner = "HolmesGPT";
    repo = "holmesgpt";
    tag = version;
    hash = "sha256-DS/8fJEeqExeNtt8Tt/yZA3kXA2bQewDBbDZpkrrVNA=";
  };

  # pyproject.toml + uv.lock are generated from upstream's poetry.lock by
  # update.sh (migrate-to-uv); upstream does not ship a uv.lock.
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  holmesOverrides = final: prev: {
    holmesgpt = prev.holmesgpt.overrideAttrs {
      inherit src version;
      # Upstream hardcodes /bin/bash for local execution, which doesn't exist on NixOS.
      # Leave YAML shebangs (run inside k8s pods) and error-message strings alone.
      postPatch = ''
        substituteInPlace \
          holmes/core/tools.py \
          holmes/plugins/toolsets/bash/common/bash.py \
          --replace-fail '"/bin/bash"' '"${bash}/bin/bash"'
      '';
    };

    # sdist-only and doesn't declare its setuptools build dependency.
    clickhouse-sqlalchemy = prev.clickhouse-sqlalchemy.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ final.resolveBuildSystem { setuptools = [ ]; };
    });
  };

  pythonSet = (callPackage pyproject-nix.build.packages { python = python313; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
      holmesOverrides
    ]
  );

  venv = pythonSet.mkVirtualEnv "holmesgpt-env" workspace.deps.default;
in
runCommand "holmesgpt-${version}"
  {
    inherit version;
    nativeBuildInputs = [ makeWrapper ];
    passthru = {
      inherit src venv;
      updateScript = ./update.sh;
    };
    meta = {
      description = "AI-powered SRE agent for incident response and troubleshooting";
      homepage = "https://github.com/HolmesGPT/holmesgpt";
      changelog = "https://github.com/HolmesGPT/holmesgpt/releases/tag/${version}";
      license = lib.licenses.asl20;
      maintainers = [ ];
      mainProgram = "holmes";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
  ''
    # kubectl is invoked by bare name from several toolsets; put it on PATH.
    makeWrapper ${venv}/bin/holmes $out/bin/holmes \
      --prefix PATH : ${lib.makeBinPath [ kubectl ]}
  ''
