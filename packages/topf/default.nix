{
  lib,
  buildGoModule,
  go_1_27,
  fetchFromGitHub,
  versionCheckHook,
}:

# go.mod requires go >= 1.27; drop the override once nixpkgs' default go catches up.
(buildGoModule.override { go = go_1_27; }) (finalAttrs: {
  pname = "topf";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "postfinance";
    repo = "topf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-frUyZtpA0iyFwHxlN5SqZ0WFfU4sMalmdkHtulg+B3I=";
  };

  vendorHash = "sha256-VLZLPM1/a1Lf5ggk4pwB/AL+Drrdfmm3f9DYjvpBKcA=";

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
