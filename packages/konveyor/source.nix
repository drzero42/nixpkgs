# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "63e0037c6fbdbfe27bc8af17c914543b5a779ed0";
    fetchSubmodules = true;
    hash = "sha256-b/fgn2S5hupGvAP6M3bt1FUiO8pHxs355r+e7MJtrrA=";
  };
}
