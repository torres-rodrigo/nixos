{ pkgs, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    wireless = {
      enable = false;

      iwd = {
        enable = true;
        settings = {
          Network = {
            EnableIPv6 = true;
          };

          Settings = {
            AutoConnect = true;
          };
        };
      };
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '';
}
