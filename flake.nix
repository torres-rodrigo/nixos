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

    outputs = { nixpkgs, home-manager, ... }:
      let
        defaultSystem = "x86_64-linux";
      in
      {
        nixosConfigurations = import ./flake/nixos-configurations.nix {
          inherit nixpkgs home-manager;
        };

        packages = import ./flake/packages.nix {
          system = defaultSystem;
        };

        devShells = import ./flake/dev-shells.nix {
          inherit nixpkgs;
          system = defaultSystem;
        };
      };
}
