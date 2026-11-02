# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (packager-friendly-tests,
# sysmon-amd-gpu, sysmon-intel-gpu, sysmon-network). Back to DevL0rd once
# they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-02";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "f42ffffaa648990f342bc746d22a10c0e80b92f6";
    fetchSubmodules = true;
    hash = "sha256-aaGbWl4+cj/tm+pR3Cpe9EmGd1VDZsOvJEja1VJKpY8=";
  };
}
