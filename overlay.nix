# Nixpkgs overlay exposing drzero42/nixpkgs packages.
# Consumers register via: nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
#
# opencode uses final.callPackage so it resolves the models-dev bundled here
# (with the jsonschema passthru) instead of the consumer's — stable nixpkgs
# ships a models-dev too old to have it.
final: prev: {
  claude-code   = prev.callPackage ./packages/claude-code { };
  kagi-cli      = prev.callPackage ./packages/kagi-cli { };
  kvitals       = prev.callPackage ./packages/kvitals { };
  models-dev    = prev.callPackage ./packages/models-dev { };
  nats-desktop  = prev.callPackage ./packages/nats-desktop { };
  opencode      = final.callPackage ./packages/opencode { };
  openshift     = prev.callPackage ./packages/openshift { };
  slumber       = prev.callPackage ./packages/slumber { };
}
