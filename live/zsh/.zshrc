# Interactive zsh setup.
[[ -o interactive ]] || return

fpath=(/run/current-system/sw/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if [[ -r /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
