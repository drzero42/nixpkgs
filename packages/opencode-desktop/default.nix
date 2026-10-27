{
  callPackage,
  opencode,
}:

# Upstream's desktop derivation; version and src follow opencode.
(callPackage "${opencode.upstreamSrc}/nix/desktop.nix" { inherit opencode; }).overrideAttrs (old: {
  # ponytail: since v2.2.0 script/build.ts reads the CLI from packages/cli/dist
  # only, while upstream's buildPhase still stages it in $OPENCODE_CLI_DIST.
  # Drop once anomalyco/opencode#59601 is fixed upstream.
  preBuild = old.preBuild + ''
    ln -s "$TMPDIR/desktop-cli" packages/cli/dist
  '';
})
