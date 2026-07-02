{
    description = "NixOS configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      sops-nix = {
        url = "github:Mic92/sops-nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };

    outputs = inputs@{ self, nixpkgs, home-manager, sops-nix, ... }:
      let
        system = "x86_64-linux";
        username = "r";
        hostname = "PC";
        stateVersion = "26.05";
      in
      {
        nixosConfigurations = import ./flake/nixos-configurations.nix {
          inherit inputs self nixpkgs home-manager sops-nix system hostname username stateVersion;
        };

        packages = import ./flake/packages.nix {
          inherit inputs self nixpkgs system;
        };

        devShells = import ./flake/dev-shells.nix {
          inherit inputs self nixpkgs system;
        };
      };
}
