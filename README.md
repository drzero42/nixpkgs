# drzero42/nixpkgs

A Nix flake with a handful of packages I use and wanted available on my machines. Nothing more ambitious than that.

Currently:

- `claude-code`
- `holmesgpt`
- `kagi-cli`
- `kvitals`

`claude-code` is already packaged in nixpkgs proper; it's here only so I always get the very latest upstream release without waiting for nixpkgs to catch up.

## Usage

As a flake input:

```nix
inputs.drzero42-nixpkgs = {
  url = "github:drzero42/nixpkgs";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then either register the overlay:

```nix
nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
```

or grab a package directly from `inputs.drzero42-nixpkgs.packages.<system>.<name>`.

## A warning

Updates run on a cron every six hours and get committed straight to `main`. Nothing is built or tested in CI, so if upstream ships something weird, this repo will happily pass it along. Expect the occasional broken build.

Use at your own risk. If you need stability, pin a commit.

## License

MIT, see [LICENSE](LICENSE).
