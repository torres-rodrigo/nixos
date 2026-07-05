{ config, repoPath, ... }:

let
  live = path:
    config.lib.file.mkOutOfStoreSymlink "${repoPath}/live/${path}";
in
{
  home.file.".config/mango/config.conf".source = live "mango/config.conf";

  # Live config example:
  # home.file.".config/example/config.toml".source = live "example/config.toml";

  # Store-managed config example:
  # home.file.".config/example/config.toml".text = ''
  #   setting = "value"
  # '';
}
