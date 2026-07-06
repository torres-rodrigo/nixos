{ host, pkgs, username, ... }:

{
  users.mutableUsers = true;

  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    description = username;
    home = host.userHome;
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "networkmanager"
      "seat"
      "video"
      "render"
      "wheel"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    shellInit = ''
      export ZDOTDIR="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    '';
  };
}
