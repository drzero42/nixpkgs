# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-17";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "9879d68dcb003bce01d86fc6d0ca26dc4e27e486";
    fetchSubmodules = true;
    hash = "sha256-KIE+fN0aXTrwpn1Y+De/s0zRtbLyzN18fm6Y0Hd9UJc=";
  };
}
