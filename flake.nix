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
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
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
          };
        };

      flake.overlays.default = import ./overlay.nix;
    };
}
