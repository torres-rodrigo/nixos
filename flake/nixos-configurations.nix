{
  nixpkgs,
  home-manager,
  hostOverrides ? { },
  extraModules ? [ ],
  ...
}:

let
  inherit (nixpkgs) lib;

  baseHosts = {
    nixos = {
      system = "x86_64-linux";
      hostname = "PC";
      username = "r";
      userHome = "/home/r";
      repoPath = "/home/r/projects/nixos";
      stateVersion = "26.05";
      configuration = ../hosts/nixos/configuration.nix;
      home = ../users/r/home.nix;
    };
  };

  hosts = lib.recursiveUpdate baseHosts hostOverrides;

  mkHost = host:
    nixpkgs.lib.nixosSystem {
      inherit (host) system;

      specialArgs = {
        inherit host;
        inherit (host) hostname username stateVersion;
      };

      modules = [
        home-manager.nixosModules.home-manager
        host.configuration
      ] ++ extraModules;
    };
in
{
  nixos = mkHost hosts.nixos;
}
