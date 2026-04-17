{
  description = "drzero42's nix package overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Darwin systems are dropped: none of the exposed packages currently
      # support them (anytype-heart is linux-only; the rest haven't been
      # validated on darwin). Re-add when a darwin-capable package lands.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, system, self', ... }:
        let
          poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
        in
        {
          # Some exposed packages have unfree-redistributable licenses
          # (anytype, anytype-heart). Allow unfree on the flake's pkgs so that
          # `nix build .#<pkg>` works without requiring NIXPKGS_ALLOW_UNFREE.
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          packages = {
            anytype-heart = pkgs.callPackage ./packages/anytype-heart { };
            claude-code = pkgs.callPackage ./packages/claude-code { };
            holmesgpt = pkgs.callPackage ./packages/holmesgpt {
              inherit (poetry2nix) mkPoetryApplication defaultPoetryOverrides;
            };
            kagi-cli = pkgs.callPackage ./packages/kagi-cli { };
            kvitals = pkgs.callPackage ./packages/kvitals { };
          };
        };

      flake.overlays.default = import ./overlay.nix;
    };
}
