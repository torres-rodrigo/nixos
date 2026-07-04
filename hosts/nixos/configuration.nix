{ hostname, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = hostname;
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = stateVersion;
}
