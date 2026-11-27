# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-27";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "c26915c82d7fb765eee33ab303813507616bbc1e";
    fetchSubmodules = true;
    hash = "sha256-JhI3MlfoE8sGG1AtdsQrf0dDPlgCfzQlre4LiB/8AsY=";
  };
}
