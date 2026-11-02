# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (packager-friendly-tests,
# sysmon-amd-gpu, sysmon-network). Back to DevL0rd once they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-02";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "0e5b8da6a1468b360a421dd69b678a3d0fe3939d";
    fetchSubmodules = true;
    hash = "sha256-o7QXKqOWXcNPsq9cnIlkmW+LVigajIgW+J14sqS5XQQ=";
  };
}
