# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-16";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "9ecd2d4827612fe01c2657463c9ae3d5637a4084";
    fetchSubmodules = true;
    hash = "sha256-tLT4yEbAbjBhPrMmNMK8lKvHH5Ls6UFyZ0aCqZ9IlAw=";
  };
}
