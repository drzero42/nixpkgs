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
    rev = "416edfe47e5b3602910df7b13243794b08289f02";
    fetchSubmodules = true;
    hash = "sha256-wlcm3+V9p3X37koqqH2MrjFOeuGTHmOV/E2jaUwdtFQ=";
  };
}
