{ ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      # Use SSH for gh-managed git operations (clone, push) instead of HTTPS tokens.
      git_protocol = "ssh";
      # Opens neovim when gh needs to edit PR descriptions or commit messages.
      editor = "nvim";
    };
  };
}
