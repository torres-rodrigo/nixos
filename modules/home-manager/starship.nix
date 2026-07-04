{ ... }:

{
  programs.zsh = {
    enable = true;
    initContent = ''
      eval "$(starship init zsh)"
    '';
  };

  xdg.configFile."starship/starship.toml".text = ''
    format = """\
    [╭─](bold 238)[ᚱ](bold #FF4450) $directory\
    $git_branch\
    $git_status\
    $fill\
    $cmd_duration
    [╰──](bold 238)$character"""

    [directory]
    truncation_length = 0
    truncate_to_repo = false
    style = "bold #7dcfff"

    [git_branch]
    format = '$symbol[$branch]($style) '

    [git_status]
    format = '([$ahead_behind$all_status]($style) )'
    ahead = '[⇡''${count}](bold yellow) '
    behind = '[⇣''${count}](bold red) '
    diverged = '[⇕⇡''${ahead_count}⇣''${behind_count}](bold red) '
    up_to_date = '[](bold #66FF00) '
    conflicted = '[](bold red) '
    deleted = '[---''${count}](bold red) '
    modified = '[!!''${count}](bold red) '
    renamed = '[»»''${count}](bold blue) '
    staged = '[+++''${count}](bold green) '
    untracked = '[?''${count}](bold red) '
    stashed = '[§''${count}](bold yellow) '
    style = 'bold white'

    [fill]
    symbol = ' '

    [cmd_duration]
    min_time = 250
    show_milliseconds = true
    format = 'took [󱦟 $duration]($style) '

    [character]
    error_symbol = "[❯](bold green)"
    success_symbol = "[❯](bold green)"
  '';
}
