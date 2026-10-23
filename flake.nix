{
  description = "drzero42's nix package overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # uv2nix stack, used by holmesgpt.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          pkgs,
          system,
          self',
          ...
        }:
        {
          # Some exposed packages have unfree-redistributable licenses.
          # Allow unfree on the flake's pkgs so that
          # `nix build .#<pkg>` works without requiring NIXPKGS_ALLOW_UNFREE.
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          formatter = pkgs.nixfmt-tree;

          packages = {
            claude-code = pkgs.callPackage ./packages/claude-code { };
            holmesgpt = pkgs.callPackage ./packages/holmesgpt {
              inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
            };
            ingress2gateway = pkgs.callPackage ./packages/ingress2gateway { };
            kagi-cli = pkgs.callPackage ./packages/kagi-cli { };
            # Built in CI only; the overlay and the cachix push leave it out
            # (see packages/konveyor/default.nix).
            konveyor = pkgs.kdePackages.callPackage ./packages/konveyor { };
            konveyor-widgets = pkgs.callPackage ./packages/konveyor-widgets { };
            kvitals = pkgs.callPackage ./packages/kvitals { };
            nats-desktop = pkgs.callPackage ./packages/nats-desktop { };
            opencode = pkgs.callPackage ./packages/opencode { };
            opencode-desktop = pkgs.callPackage ./packages/opencode-desktop {
              opencode = self'.packages.opencode;
            };
            openshift = pkgs.callPackage ./packages/openshift { };
            topf = pkgs.callPackage ./packages/topf { };
          };
        };

      flake.overlays.default = import ./overlay.nix { inherit inputs; };
    };
}
