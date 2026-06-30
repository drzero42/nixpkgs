{
  description = "drzero42's nix package overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, system, self', ... }:
        {
          # Some exposed packages have unfree-redistributable licenses.
          # Allow unfree on the flake's pkgs so that
          # `nix build .#<pkg>` works without requiring NIXPKGS_ALLOW_UNFREE.
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          packages = {
            claude-code = pkgs.callPackage ./packages/claude-code { };
            kagi-cli = pkgs.callPackage ./packages/kagi-cli { };
            kvitals = pkgs.callPackage ./packages/kvitals { };
            nats-desktop = pkgs.callPackage ./packages/nats-desktop { };
            openshift = pkgs.callPackage ./packages/openshift { };
            slumber = pkgs.callPackage ./packages/slumber { };
          };
        };

      flake.overlays.default = import ./overlay.nix;
    };
}
