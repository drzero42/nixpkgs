# Nixpkgs overlay exposing drzero42/nixpkgs packages.
# Consumers register via: nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
#
# opencode uses final.callPackage so it resolves the models-dev bundled here
# (with the jsonschema passthru) instead of the consumer's — stable nixpkgs
# ships a models-dev too old to have it.
#
# bun is pinned from this flake's own nixpkgs input instead of taken from the
# consumer's `prev`: opencode's node_modules is a fixed-output derivation that
# runs `bun install` at build time, and its outputHash is computed by the
# update bot against this flake's nixpkgs. A consumer on a different nixpkgs
# (e.g. a stable channel shipping a different bun) would produce different
# node_modules bytes and fail the hash check whenever the CI-built output
# isn't substitutable from the binary cache.
# NOTE: consumers must NOT follow this flake's nixpkgs input to their own,
# or the pin is defeated (the follow replaces it with the consumer's tree).
{ inputs }:
final: prev:
let
  pinned = import inputs.nixpkgs {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  claude-code      = prev.callPackage ./packages/claude-code { };
  kagi-cli         = prev.callPackage ./packages/kagi-cli { };
  kvitals          = prev.callPackage ./packages/kvitals { };
  models-dev       = prev.callPackage ./packages/models-dev { };
  nats-desktop     = prev.callPackage ./packages/nats-desktop { };
  opencode         = final.callPackage ./packages/opencode { bun = pinned.bun; };
  opencode-desktop = final.callPackage ./packages/opencode-desktop { };
  openshift        = prev.callPackage ./packages/openshift { };
  slumber          = prev.callPackage ./packages/slumber { };
  topf             = prev.callPackage ./packages/topf { };
}
