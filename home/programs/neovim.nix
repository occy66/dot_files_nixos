{ pkgs, ... }:
{
  # Non usiamo programs.neovim perché withRuby/withPython3=false genera un
  # init.lua gestito da HM che clobberebbe ~/.nv-ide/init.lua (symlink).
  home.packages = with pkgs; [
    neovim

    # LSP servers
    lua-language-server
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    vim-language-server
    dockerfile-language-server
    solargraph
    copilot-language-server

    # Formatter
    prettierd
    stylua
    rubocop

    # Linter
    hadolint
    shellcheck

    # Tool richiesti da plugin neovim
    ripgrep
    fd
    git
    lazygit
    delta
    nodejs
    tree-sitter
    gcc
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vi  = "nvim";
    vim = "nvim";
  };
}
