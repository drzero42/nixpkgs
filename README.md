# drzero42/nixpkgs

A public Nix flake exposing a small overlay of packages, auto-updated every six hours.

## Packages

| Name | Upstream |
|---|---|
| `anytype-heart` | [anyproto/anytype-heart](https://github.com/anyproto/anytype-heart) |
| `claude-code` | [@anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code) |
| `holmesgpt` | [HolmesGPT/holmesgpt](https://github.com/HolmesGPT/holmesgpt) |
| `kagi-cli` | [drzero42/kagi-cli](https://github.com/drzero42/kagi-cli) |
| `kvitals` | widget companion tool |

> `anytype` is temporarily not exposed by this flake — its upstream `default.nix`
> pins `electron_37`, which was removed from `nixos-unstable` on 2026-03-20. It
> will return once the package is updated to a supported electron release.

## Usage

Add as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    drzero42-nixpkgs = {
      url = "github:drzero42/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Register the overlay:

```nix
nixpkgs.overlays = [ inputs.drzero42-nixpkgs.overlays.default ];
```

Or consume a package directly: `inputs.drzero42-nixpkgs.packages.x86_64-linux.anytype`.

## Auto-updates

GitHub Actions runs `packages/<name>/update.sh` and `nix flake update` every six hours
(00:17, 06:17, 12:17, 18:17 UTC) and commits changes directly to `main` as
`github-actions[bot]`. There are **no CI builds** — consumers detect breakage at build time.

## License

MIT — see [LICENSE](LICENSE).
