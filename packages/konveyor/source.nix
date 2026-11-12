# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "993c57f3537bc288c7f0864a0fbf2556f79041f9";
    fetchSubmodules = true;
    hash = "sha256-BVuVb7q4sTv55Phfl9pyipckhlpJqsISXPNpq4ZHFew=";
  };
}
