# Nixpkgs overlay exposing drzero42/nixpkgs packages.
# Consumers register via: nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
final: prev: {
  claude-code   = prev.callPackage ./packages/claude-code { };
  kagi-cli      = prev.callPackage ./packages/kagi-cli { };
  kvitals       = prev.callPackage ./packages/kvitals { };
  nats-desktop  = prev.callPackage ./packages/nats-desktop { };
  holmesgpt     = prev.callPackage ./packages/holmesgpt { };
  openshift     = prev.callPackage ./packages/openshift { };
  slumber       = prev.callPackage ./packages/slumber { };
}
