# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (sysmon-intel-gpu, sysmon-network).
# Back to DevL0rd once they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-03";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "e5ea4d0f9927441814e9e06d3da0777dff11be98";
    fetchSubmodules = true;
    hash = "sha256-ZEFV+r4fchI8P2ahDvv/FXLT0amTIBq8ieq+LEw7gYo=";
  };
}
