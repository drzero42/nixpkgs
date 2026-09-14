# drzero42/nixpkgs

A Nix flake with a handful of packages I use and wanted available on my machines. Nothing more ambitious than that.

Currently:

- `claude-code`
- `kagi-cli`
- `kvitals`
- `nats-desktop`
- `opencode`
- `openshift`
- `slumber`

`claude-code` is already packaged in nixpkgs proper; it's here only so I always get the very latest upstream release without waiting for nixpkgs to catch up.

`models-dev` is also bundled (opencode builds against it): stable nixpkgs ships a `models-dev` too old for opencode's needs, so the overlay provides its own.

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

## Binary cache

Every push to `main` is built by GitHub Actions and pushed to a public [Cachix](https://www.cachix.org) cache, so consumers can substitute instead of building. Only `x86_64-linux` is built.

```nix
nix.settings = {
  substituters = [ "https://drzero42.cachix.org" ];
  trusted-public-keys = [ "drzero42.cachix.org-1:+44rOXC+rRBIVHO8kVcAaPnQf9d847Jwf8KgY8AUZAM=" ];
};
```

Or one-off, without touching system config:

```bash
nix build github:drzero42/nixpkgs#opencode \
  --extra-substituters https://drzero42.cachix.org \
  --extra-trusted-public-keys drzero42.cachix.org-1:+44rOXC+rRBIVHO8kVcAaPnQf9d847Jwf8KgY8AUZAM=
```

## A warning

Updates run on a cron every six hours and get committed straight to `main`. Packages are built for the cache but nothing is tested, so if upstream ships something weird, this repo will happily pass it along. Expect the occasional broken build.

Use at your own risk. If you need stability, pin a commit.

## License

MIT, see [LICENSE](LICENSE).
