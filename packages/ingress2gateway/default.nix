{
  lib,
  ingress2gateway,
  fetchFromGitHub,
}:

# nixpkgs lags upstream (0.5.0 there); only the version is bumped here.
ingress2gateway.overrideAttrs (
  finalAttrs: old: {
    version = "1.2.0";

    src = fetchFromGitHub {
      owner = "kubernetes-sigs";
      repo = "ingress2gateway";
      tag = "v${finalAttrs.version}";
      hash = "sha256-OWApp9IpKgRgyBnB3OKZE6jCBHui5ipkLtUeU0D5IwY=";
    };

    vendorHash = "sha256-9YV4T7sDhb/1ZgpjrIm4AWFx1OoZbY9u3jpGlCM4edc=";

    # e2e tests (added in 1.x) need a live cluster.
    excludedPackages = [ "e2e" ];

    ldflags = old.ldflags ++ [
      "-X github.com/kubernetes-sigs/ingress2gateway/pkg/i2gw.Version=v${finalAttrs.version}"
    ];

    meta = old.meta // {
      platforms = lib.platforms.unix;
    };
  }
)
