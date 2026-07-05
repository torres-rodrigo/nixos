{ hostname, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/app-policy.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/dns.nix
    ../../modules/nixos/firewall.nix
    ../../modules/nixos/greetd.nix
    ../../modules/nixos/hardware-intel.nix
    ../../modules/nixos/home-manager.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/nix-maintenance.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/plymouth.nix
    ../../modules/nixos/storage.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
