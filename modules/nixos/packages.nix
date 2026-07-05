{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsa-utils # ALSA command-line utilities
    bat # cat replacement
    btrfs-progs # Btrfs filesystem CLI utilities
    btop # Interactive TUI resource monitor
    caligula # TUI for disk imaging
    curl # HTTP/HTTPS/FTP transfer tool
    deadnix # Finds unused Nix code
    delta # Enhanced diff viewer
    dust # du replacement - visual disk usage tree
    eza # ls replacement
    exfatprogs # exFAT filesystem support (USB interop)
    fd # find replacement
    ffmpeg # Media processing
    fzf # Fuzzy finder
    git # Distributed version control system
    jq # JSON processor and pretty-printer
    less # Pager
    mold # Modern high-speed linker
    ncdu # Interactive disk usage navigator
    nix-output-monitor # Improves Nix build output readability
    nix-tree # Inspects why dependencies are in a Nix closure
    nixfmt # Official formatter for Nix files
    nvd # Compares NixOS generation package versions
    openssh # SSH client
    pamixer # PulseAudio/PipeWire command-line mixer
    pavucontrol # PulseAudio/PipeWire volume control GUI
    pwvucontrol # PipeWire volume control GUI
    qpwgraph # PipeWire graph patchbay
    ripgrep # grep replacement
    starship # Fast cross-shell prompt
    statix # Lints Nix code and catches common issues
    unzip # ZIP archive extraction
    wezterm # GPU-accelerated terminal emulator
    wget # File downloader
    zsh-autosuggestions # Fish-style inline command suggestions
    zsh-completions # Extended zsh completion definitions
    zsh-syntax-highlighting # Real-time command syntax colouring
  ];
}
