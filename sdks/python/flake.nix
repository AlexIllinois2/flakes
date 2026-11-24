{
  description = "Python dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonEnv = pkgs.python312.withPackages (ps: with ps; [
          numpy
          requests
          pip
          virtualenv
        ]);
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            (pkgs.python311.withPackages (ps: with ps; [
              numpy pandas matplotlib jupyterlab scikit-learn
            ]))
            pkgs.jq
          ];
        };
      });
}