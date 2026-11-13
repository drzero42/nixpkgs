# Shared by konveyor and konveyor-widgets so both always build the same
# upstream commit. packages/konveyor/update.sh bumps it.
{ fetchFromGitHub }:
{
  version = "0-unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "DevL0rd";
    repo = "Konveyor";
    rev = "60b3b57326ed5dcb649a93ea60ab46a43a39113f";
    fetchSubmodules = true;
    hash = "sha256-Ehl9SEvO5MwjsYFrN9dmhZh3/Wp6tB9UE8Efb+7vpYQ=";
  };
}
