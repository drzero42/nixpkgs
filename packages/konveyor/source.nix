# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-17";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "178b9f2291401a1bdf644ca1019d0940ae777231";
    fetchSubmodules = true;
    hash = "sha256-cwfvoapLqnUpL9pVNTwex7M7QWtww7UGsbl/vuX1QEU=";
  };
}
