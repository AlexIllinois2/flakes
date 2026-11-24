{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, home-manager, nur, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "v"; 
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nur.overlays.default ];
      };
    in
    {
      nixosConfigurations.asus = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/asus/asus.nix
        ];
        specialArgs = {
          inherit self; 
          inherit inputs;
          inherit nur;
          inherit username;
        };
      };
    };
}
