{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # Keep home dir clean: zsh reads rc files from here instead of ~/.zshrc, ~/.zprofile, etc.
    dotDir = "${config.home.homeDirectory}/.config/zsh";

    # Plugin (sostituiscono zinit)
    antidote = {
      enable = false; # usiamo plugins manuali per compatibilità p10k
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "enhancd";
        src = pkgs.fetchFromGitHub {
          owner = "babarot";
          repo = "enhancd";
          rev = "5afb4eb6ba36c15821de6e39c0a7bb9d6b0ba415";
          hash = "sha256-pKQbwiqE0KdmRDbHQcW18WfxyJSsKfymWt/TboY2iic=";
        };
        file = "init.sh";
      }
    ];

    shellAliases = {
      df = "duf";
    };

    history = {
      # Large buffer shared across all sessions; timestamps stored (extended = true).
      size = 290000;
      save = 290000;
      path = "$HOME/.zhistory";
      extended = true;   # Store timestamp with each command (needed by atuin)
      ignoreDups = true;
      ignoreSpace = true; # Commands prefixed with a space are not saved (useful for secrets)
      share = true;        # Append to history immediately so all open shells see new entries
    };

    # Variabili d'ambiente
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LANG = "it_IT.UTF-8";
      LC_ALL = "it_IT.UTF-8";
      BAT_THEME = "tokyonight_night";
      GOPATH = "$HOME/Dev/go";
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
      ENHANCD_FILTER = "fzf:fzy:peco";
    };

    initContent = ''
      #########################################################################
      # IRIS (autocomplete/navigation context-aware)
      # Deve stare per primo: "iris init zsh" fa "exec iris" nella shell non
      # ancora figlia di iris, sostituendo il processo. Tutto quello che sta
      # dopo in questo file non verrebbe mai eseguito in quella shell (né
      # servirebbe: verrà rieseguito identico dalla shell reale che iris crea
      # al suo posto). Mettendolo prima di tutto evitiamo di far girare due
      # volte roba come il p10k instant prompt (che si lamenterebbe di non
      # essere stato "chiuso" correttamente) o il tmux autostart.
      #########################################################################
      # eval "$(iris init zsh)"

      #########################################################################
      # NIXOS BANNER
      #########################################################################
      print -P "%F{51}NixOS ''$(nixos-version | cut -d'.' -f1,2)%f"

      #########################################################################
      # P10K INSTANT PROMPT
      #########################################################################
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      #########################################################################
      # TMUX AUTO-START
      #########################################################################
      if [[ -z "$TMUX" ]] && [[ ! $(tmux ls) ]] 2>/dev/null; then
        tmux new -s λ
      fi

      #########################################################################
      # SETOPT
      #########################################################################
      setopt extended_history
      setopt hist_expire_dups_first
      setopt hist_ignore_all_dups
      setopt hist_ignore_space
      setopt hist_verify
      setopt inc_append_history
      setopt share_history
      setopt always_to_end
      setopt hash_list_all
      setopt complete_in_word
      setopt nocorrect
      setopt list_ambiguous
      setopt nolisttypes
      setopt listpacked
      setopt automenu
      setopt vi
      unsetopt BEEP

      #########################################################################
      # COMPLETION STYLES (fzf-tab)
      #########################################################################
      zstyle ':completion:*' completer _expand _complete _ignored _approximate
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu no
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:processes' command 'ps -au$USER'
      zstyle ':completion:complete:*:options' sort false
      zstyle ':fzf-tab:complete:_zlua:*' query-string input
      zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
      zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts \
        --preview='ps --pid=$( echo {1} | tr -d "[]") -o cmd --no-headers -w -w' \
        --preview-window=down:3:wrap
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ":completion:*:git-checkout:*" sort false
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      #########################################################################
      # CHPWD: list files on cd; auto-fetch when entering a different git repo
      #########################################################################
      chpwd() {
        set -- "$(git rev-parse --show-toplevel 2>/dev/null)"
        if [ -n "$1" ] && [ "$1" != "$vc_root" ]; then
          vc_root="$1"
          git fetch
        fi
        eza --git --icons --classify --group-directories-first --time-style=long-iso --group --color-scale
      }

      #########################################################################
      # FZF
      #########################################################################
      export FZF_DEFAULT_OPTS="
      --ansi
      --layout=reverse
      --info=inline-right
      --height=50%
      --multi
      --preview-window=right:50%:sharp:cycle
      --preview '([[ -f {} ]] && (bat --style=numbers --color=always --line-range :500 {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2>/dev/null | head -200'
      --prompt='λ -> '
      --pointer='❯'
      --marker='✓'
      --color=bg+:#283457
      --color=bg:#16161e
      --color=border:#27a1b9
      --color=fg:#c0caf5
      --color=gutter:#16161e
      --color=header:#ff9e64
      --color=hl+:#2ac3de
      --color=hl:#2ac3de
      --color=info:#545c7e
      --color=marker:#ff007c
      --color=pointer:#ff007c
      --color=prompt:#2ac3de
      --color=query:#c0caf5:regular
      --color=scrollbar:#27a1b9
      --color=separator:#ff9e64
      --color=spinner:#ff007c
      "
      export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

      # Load fzf key bindings (Ctrl-T, Ctrl-R, Alt-C) and tab completions.
      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      #########################################################################
      # ATUIN (history search)
      #########################################################################
      eval "$(atuin init zsh)"

      #########################################################################
      # ZOXIDE (smart cd)
      #########################################################################
      eval "$(zoxide init zsh)"

      #########################################################################
      # YAZI: wrapper che cd nella directory all'uscita
      #########################################################################
      function ya() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      #########################################################################
      # FANCY CTRL-Z
      #########################################################################
      function fg-fzf() {
        job="$(jobs | fzf -0 -1 | sed -E 's/\[(.+)\].*/\1/')" && echo "" && fg %''$job
      }
      function fancy-ctrl-z() {
        if [[ $#BUFFER -eq 0 ]]; then
          BUFFER=" fg-fzf"
          zle accept-line -w
        else
          zle push-input -w
          zle clear-screen -w
        fi
      }
      zle -N fancy-ctrl-z
      bindkey '^Z' fancy-ctrl-z

      #########################################################################
      # P10K: segmento rails version
      #########################################################################
      function prompt_my_rails() {
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
          if [[ -f "''${repo_root}/Gemfile" ]]; then
            if command -v rails >/dev/null 2>&1; then
              local rails_version=$(rails -v | cut -d' ' -f2)
              p10k segment -s RAILS -f red -i "" -t "''${rails_version}"
            fi
          fi
        fi
      }

      #########################################################################
      # TOGGLE DAY/NIGHT
      #########################################################################
      toggle_day_night() {
        LAZY_FILE="$HOME/.config/nvim/lua/config/lazy.lua"
        GHOSTTY_FILE="$HOME/.config/ghostty/config"
        IMPORT_LINE=$(grep -n 'import = "plugins.colorschemes.' "$LAZY_FILE" | cut -d: -f1)
        if grep -q 'import = "plugins.colorschemes.tokyonight"' "$LAZY_FILE"; then
          sed -i "''${IMPORT_LINE}s/import = \"plugins.colorschemes.tokyonight\"/import = \"plugins.colorschemes.github\"/" "$LAZY_FILE"
          sed -i "2s/.*/theme = \"GitHub Light Default\"/" "$GHOSTTY_FILE"
          echo "Theme: github (light)"
        elif grep -q 'import = "plugins.colorschemes.github"' "$LAZY_FILE"; then
          sed -i "''${IMPORT_LINE}s/import = \"plugins.colorschemes.github\"/import = \"plugins.colorschemes.tokyonight\"/" "$LAZY_FILE"
          sed -i "2s/.*/theme = \"TokyoNight Night\"/" "$GHOSTTY_FILE"
          echo "Theme: tokyonight (dark)"
        fi
        command -v ghostty >/dev/null 2>&1 && pkill -SIGUSR2 ghostty
      }

      #########################################################################
      # QUICKPR
      #########################################################################
      quickpr() {
        branch=$1
        git checkout -b $branch
        git add .
        git commit -m "''${2:-Quick commit}"
        gh pr create --fill --draft --assignee @me
      }

      #########################################################################
      # GCLOUD (optional — only sourced if the SDK is installed at the default path)
      #########################################################################
      if [ -f '/opt/google-cloud-sdk/path.zsh.inc' ]; then
        source '/opt/google-cloud-sdk/path.zsh.inc'
      fi

      #########################################################################
      # CTRL-G: fzf picker per progetti Google Cloud
      #########################################################################
      function gcloud-project-widget() {
        local project
        project=$(gcloud projects list --format="value(projectId)" 2>/dev/null | fzf --prompt="GCloud project> " --height=40% --layout=reverse --border)
        if [[ -n "$project" ]]; then
          gcloud config set project "$project" >/dev/null 2>&1
          POSTDISPLAY=" [GCloud: $project]"
          zle reset-prompt
        fi
        zle reset-prompt
      }
      zle -N gcloud-project-widget
      bindkey '^G' gcloud-project-widget

      #########################################################################
      # PATH
      #########################################################################
      export PATH=$PATH:/usr/local/go/bin:~/.local/bin:~/bin

      #########################################################################
      # PRIVATE ALIASES AND ENV VARS (sourced from nubem_dot_files via home.file symlinks)
      #########################################################################
      [[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
      [[ -f ~/.nubem_env ]] && source ~/.nubem_env

      #########################################################################
      # P10K
      #########################################################################
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };
}
