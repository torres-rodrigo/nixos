{ host, stateVersion, username, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit stateVersion username;
      repoPath = host.repoPath;
    };

    users.${username} = import host.home;
  };
}
