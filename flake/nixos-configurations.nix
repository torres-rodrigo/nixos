{ nixpkgs, home-manager, system, hostname, username, stateVersion, ... }:

{
  nixos = nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit hostname username stateVersion;
    };

    modules = [
      home-manager.nixosModules.home-manager
      ../hosts/nixos/configuration.nix
    ];
  };
}
