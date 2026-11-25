---
name: nix-local-fixed-output
description: Register a locally downloaded file as a Nix store fixed-output path so fetchurl sources build offline. Use when a Nix, NUR, or nixpkgs package cannot download a large source file already present on disk.
---

# Nix Local Fixed-Output Source

Use this when a package's `fetchurl` (a fixed-output derivation, FOD) cannot download its source — large file, slow or blocked network — and the user already has that exact file locally.

## Steps

1. Locate the expected hash and URL in the package definition. Read the package `.nix` file, or inspect the derivation when the source is in NUR or another flake:

```sh
nix derivation show /nix/store/<hash>-<pname>.drv   # look at urls and outputHash
```

2. Verify the local file matches the expected hash. An FOD output path is derived from its content hash, so a mismatch means Nix will still re-download.

```sh
nix hash file --type sha256 --sri /path/to/local-file
```

3. Register the file into the store as a fixed-output path. Use the algorithm the package declares (`sha256` for the usual `fetchurl`). The basename must be identical to the fetched name.

```sh
nix-store --add-fixed sha256 /path/to/local-file
```

4. A match produces exactly the store path the derivation expects, so no edit to any nix file is needed. Confirm it resolves offline:

```sh
nix eval --offline --raw '.#nixosConfigurations.<host>.pkgs.nur.repos.<user>.<pkg>.src.outPath'
```

5. Rebuild. The source is taken from the store; only unpack and patch phases run locally.

```sh
sudo nixos-rebuild switch --flake /path/to/flake#<host>
```

## Notes

- The store path is not GC-rooted. `nix-collect-garbage` deletes it and the download returns. Re-run step 3, or root it with `nix-store --realise` plus a profile link.
- If the local file cannot be made to match (different build or hash), or you cannot use `--add-fixed`, override the source instead with `builtins.storePath` or an impure local path through `overrideAttrs`, which requires an impure evaluation.
- Do not edit the upstream package definition when `--add-fixed` already satisfies the FOD.
