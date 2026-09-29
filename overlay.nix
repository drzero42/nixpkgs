# Nixpkgs overlay exposing drzero42/nixpkgs packages.
# Consumers register via: nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
#
# Hands out this flake's own `packages` (built against its own nixpkgs input)
# instead of re-calling the recipes against the consumer's `prev`. The store
# paths then match what CI pushes to drzero42.cachix.org, so consumers
# substitute instead of building. It also keeps opencode's bun-built
# node_modules on the nixpkgs its outputHash was computed against.
# NOTE: consumers must NOT follow this flake's nixpkgs input to their own,
# or the store paths diverge from the cached ones again.
{ inputs }:
final: prev: inputs.self.packages.${prev.stdenv.hostPlatform.system} or { }
