# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-28";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "f8fab0134a0607bad9f31f0747b9076de77196b1";
    fetchSubmodules = true;
    hash = "sha256-6W1qgCaP16NPKLecyeIQ46m1s+pJYFax5+bABiIws1Y=";
  };
}
