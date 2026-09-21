{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CLI essenziali
    unzip
    file
    tmuxp
    htop
    ncdu
    croc
    graphviz
    plocate
    nix-graph      # nix-tree migliore
    jq             # richiesto da core/claude/statusline.sh
    gnupg
    gnumake
    html-tidy
    unrar          # unfree, richiede config.allowUnfree = true (già in flake.nix)
    rsync

    # CLI moderni (sostituiscono zinit downloads)
    eza
    bat
    bat-extras.batgrep
    bat-extras.batdiff
    bat-extras.batman
    ripgrep
    fd
    delta
    duf

    # Dev tools
    python3
    hyprpicker
    cloc
    lazygit
    lazydocker
    gh           # GitHub CLI
    git-ftp
    overmind     # process manager (Procfile)
    devenv       # ambienti di sviluppo per-progetto (Ruby, Node, Postgres, Redis)

    # Shell utilities
    fzf
    zoxide
    atuin
    prettyping
    yazi            # file manager TUI (wrapper con cwd persistence in zsh.nix)
    dig

    # 1Password CLI
    _1password-cli

    # Network / Remote
    nmap
    net-tools
    netwatch
    libpcap

    # Wayland tools
    wdisplays
    cliphist
    grim   # screenshot Wayland
    slurp  # region selector (usato da grim)
    socat  # usato da hypr-lid-watch (hyprland-laptop.nix) per ascoltare gli eventi di Hyprland

    # Database
    dbeaver-bin

    # Editor / Cloud
    vscode
    google-cloud-sdk

    # Varie
    xdg-utils
    fastfetch
    libheif        # heif-convert

    # AI
    claude-code
    github-copilot-cli

    # Shell autocomplete/navigation
    # iris
  ];
}
