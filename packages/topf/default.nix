{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "topf";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "postfinance";
    repo = "topf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NRKRROq6uxLlAHCtpT+s+eBVjFgf8qjjwlYGhdNApUs=";
  };

  vendorHash = "sha256-9xYy1Ep7bZ0nW63fmrxiqfOrHWt7Kcn+zGhcjBpdvYY=";

  subPackages = [ "cmd/topf" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Talos orchestrator by PostFinance";
    homepage = "https://github.com/postfinance/topf";
    changelog = "https://github.com/postfinance/topf/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "topf";
    platforms = lib.platforms.unix;
  };
})
