{ pkgs, username, ... }:

let
  mangoSession = pkgs.writeShellScript "mango-session" ''
    export XDG_CURRENT_DESKTOP=mango
    export XDG_SESSION_DESKTOP=mango
    export XDG_SESSION_TYPE=wayland

    exec ${pkgs.dbus}/bin/dbus-run-session -- \
      ${pkgs.mangowc}/bin/mango -c /home/${username}/.config/mango/config.conf
  '';
in

{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${mangoSession}";
        user = username;
      };
    };
  };
}
