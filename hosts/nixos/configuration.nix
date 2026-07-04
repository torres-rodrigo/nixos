{ hostname, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/firewall.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
