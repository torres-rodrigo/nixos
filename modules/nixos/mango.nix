{ pkgs, ... }:

{
  programs.mangowc = {
    enable = true;
    package = pkgs.mangowc;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.mango = {
      binPath = "/run/current-system/sw/bin/mango";
      prettyName = "Mango WM";
      comment = "Mango compositor managed by UWSM";
      extraArgs = [
        "-c"
        "/home/r/.config/mango/config.conf"
      ];
    };
  };
}
