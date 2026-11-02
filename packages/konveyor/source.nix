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
    rev = "6421cc108fad61694b90d9a51602ccc073b2d900";
    fetchSubmodules = true;
    hash = "sha256-tb5zpTcesSdkqhMoJ6IydLDGElMZfR4KL223X7Te3i0=";
  };
}
