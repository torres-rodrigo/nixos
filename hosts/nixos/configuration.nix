{ hostname, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/firewall.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
