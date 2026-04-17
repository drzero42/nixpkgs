# Nixpkgs overlay exposing drzero42/nixpkgs packages.
# Consumers register via: nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
final: prev: {
  anytype-heart = prev.callPackage ./packages/anytype-heart { };
  claude-code   = prev.callPackage ./packages/claude-code { };
  kagi-cli      = prev.callPackage ./packages/kagi-cli { };
}
