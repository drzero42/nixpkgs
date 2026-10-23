# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor packager-friendly-paths (tool lookup on PATH)
# before it goes upstream; back to DevL0rd once merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-10-23";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "7f2b5b242024ad546ebd62710ebb10848da061db";
    fetchSubmodules = true;
    hash = "sha256-Fl7zfoZhWb3zWpQ0eOS2Es55vNzGl1LvR499WZh6tms=";
  };
}
