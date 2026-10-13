{
  callPackage,
  opencode,
}:

# Upstream's desktop derivation; version and src follow opencode.
callPackage "${opencode.upstreamSrc}/nix/desktop.nix" { inherit opencode; }
