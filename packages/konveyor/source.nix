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
    rev = "abe23b9a9ff5d3ea796f1d8a6b53edee93347f2a";
    fetchSubmodules = true;
    hash = "sha256-vqViaSx02QYqyExD8LuaYbBLBTD1DOjW4uHT9PsvaE8=";
  };
}
