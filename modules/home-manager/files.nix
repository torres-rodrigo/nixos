{ config, repoPath, ... }:

let
  live = path:
    config.lib.file.mkOutOfStoreSymlink "${repoPath}/live/${path}";
in
{
  home.file.".config/mango/config.conf".source = live "mango/config.conf";
  home.file.".config/zsh/.zprofile".source = live "zsh/.zprofile";
  home.file.".config/zsh/.zshenv".source = live "zsh/.zshenv";
  home.file.".config/zsh/.zshrc".source = live "zsh/.zshrc";

  # Live config example:
  # home.file.".config/example/config.toml".source = live "example/config.toml";

  # Store-managed config example:
  # home.file.".config/example/config.toml".text = ''
  #   setting = "value"
  # '';
}
