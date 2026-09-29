{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "topf";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "postfinance";
    repo = "topf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-avrcOu+6hGqr/wtxQl/ysf7E76b+XtGf2lxDrJqnzJY=";
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
