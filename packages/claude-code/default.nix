{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_22,
  procps,
}:
buildNpmPackage rec {
  pname = "claude-code";
  version = "2.1.128";

  nodejs = nodejs_22; # required for sandboxed Nix builds on Darwin

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-cR6qGXBxU7rgzJUcxsmCUKqEcRQBWmFJgPxtSsXSW64=";
  };

  npmDepsHash = "sha256-9bShd/mB5RXFLZSgC3gBsgV3aWK+EYyXa2Im02zECxY=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  AUTHORIZED = "1";

  # `claude-code` tries to auto-update by default, this disables that functionality.
  # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : ${procps}/bin
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [
      malo
    ];
    mainProgram = "claude";
  };
}
