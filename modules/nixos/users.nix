{ pkgs, username, ... }:

{
  users.mutableUsers = true;

  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  programs.zsh.enable = true;
}
