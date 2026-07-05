{ pkgs, ... }:

{
  programs.mangowc = {
    enable = true;
    package = pkgs.mangowc;
  };
}
