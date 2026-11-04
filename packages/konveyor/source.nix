# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (sysmon-intel-gpu, sysmon-network,
# panel-width-reprobe).
# Back to DevL0rd once they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-04";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "a0f7bd206ba4b3e9f396923f583271f6e2c795f8";
    fetchSubmodules = true;
    hash = "sha256-HGUCizOvFkn/4kmwpIEn7fBpZTMzHXYjwkZtzImlDrQ=";
  };
}
