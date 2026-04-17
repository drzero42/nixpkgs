{ pkgs, ... }:
{
  packages = with pkgs; [
    nixfmt-rfc-style
    nix-update
    jq
    curl
  ];

  languages.nix.enable = true;
}
