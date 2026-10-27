# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (packager-friendly-paths,
# packager-friendly-tests, sysmon-amd-gpu, sysmon-network). Back to DevL0rd
# once they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-10-27";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "29369d7c670f9ebefe202e4a4df01eace5874c42";
    fetchSubmodules = true;
    hash = "sha256-lQ46JAPCduYqjP40+izzAURodvVJIgUt/z1QnTWqOpM=";
  };
}
