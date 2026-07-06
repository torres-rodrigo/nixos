{ host, lib, pkgs, username, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = lib.concatStringsSep " " [
          "${pkgs.uwsm}/bin/uwsm"
          "start"
          "-F"
          "--"
          "/run/current-system/sw/bin/mango"
          "-c"
          "${host.userHome}/.config/mango/config.conf"
        ];
        user = username;
      };
    };
  };
}
