# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "8017f16826ad579632abd85865936b24b564ef67";
    fetchSubmodules = true;
    hash = "sha256-aKAFuYmFLRVJ4ekGyqe9lfvoKOn4GCMGH7qt0tstmKc=";
  };
}
