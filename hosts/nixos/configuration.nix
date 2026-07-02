{ hostname, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = hostname;
  time.timeZone = "America/Montevideo";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = stateVersion;
}
