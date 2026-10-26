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
    rev = "52b598ec66c5cddfb96bb93a47f5bb246fe875fb";
    fetchSubmodules = true;
    hash = "sha256-Cl06SHDwa5L4DZNFXeow5SY9gG165ZCh4BVtILD2kdg=";
  };
}
