{ stateVersion, ... }:

{
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/files.nix
    ../../modules/home-manager/programs.nix
  ];

  home.stateVersion = stateVersion;
}
