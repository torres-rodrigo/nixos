{ pkgs, username, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.zsh}/bin/zsh --login";
        user = username;
      };
    };
  };
}
