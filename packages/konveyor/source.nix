# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
# Dog-fooding drzero42/Konveyor's drzero42 branch: upstream main with our
# not-yet-upstream branches merged in (packager-friendly-paths,
# packager-friendly-tests, sysmon-amd-gpu, sysmon-network). Back to DevL0rd
# once they're merged.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-10-26";

  src = fetchFromGitHub {
    owner = "drzero42";
    repo = "Konveyor";
    rev = "685ae9d7fb0bf05b953d2921e52127e53d01f663";
    fetchSubmodules = true;
    hash = "sha256-mVhn5vfqCnxd9is3WaxOz6TgEOH7wecCWnwXN/Ru7l4=";
  };
}
