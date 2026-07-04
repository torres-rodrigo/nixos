{ stateVersion, username, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit stateVersion username;
      repoPath = "/home/r/projects/nixos";
    };

    users.${username} = import ../../users/r/home.nix;
  };
}
