{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    # C-a matches screen muscle memory; frees C-b for use in vim/neovim.
    prefix = "C-a";
    # Vi-style bindings in copy mode (v to select, y to yank).
    keyMode = "vi";
    mouse = true;
    historyLimit = 50000;
    # Start window/pane numbering at 1 so Mod+1 on the keyboard maps to the first window.
    baseIndex = 1;
    # Minimal escape delay so Escape in neovim is not interpreted as a prefix sequence.
    escapeTime = 1;
    # tmux-256color enables true color and italic support (combined with terminal-overrides below).
    terminal = "tmux-256color";
    # Pass focus-in/focus-out events to neovim so autoread and GitSigns work correctly.
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      yank                # System clipboard integration (Wayland-aware)
      vim-tmux-navigator  # Unified Ctrl-hjkl navigation between vim splits and tmux panes
      tmux-fzf            # Fuzzy-search sessions/windows/panes with fzf
      open                # Open files/URLs from tmux copy mode
      extrakto            # Extract text from the pane and pipe it into a command
      prefix-highlight    # Shows [prefix] indicator in the status bar when prefix is active
    ];

    extraConfig = ''
      set-option -g default-shell ${pkgs.zsh}/bin/zsh
      set-option -g default-command ${pkgs.zsh}/bin/zsh

      # True color (24-bit) + undercurl/underline-color support for Ghostty/xterm-256color.
      set-option -ga terminal-overrides ',xterm-256color:Tc'
      set-option -ga terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set-option -ga terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # Prefix
      bind C-a send-prefix
      unbind C-b

      # Panes
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+

      # Sync panes
      bind C-s set-window-option synchronize-panes

      # Attiva sessione nella directory corrente
      bind C-c attach-session -c "#{pane_current_path}"

      # Reload
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Copy mode Wayland
      bind Escape copy-mode
      bind C-p run-shell "tmux set-buffer \"$(wl-paste)\"; tmux paste-buffer"
      bind C-y run-shell "tmux show-buffer | wl-copy"
      unbind p
      bind p paste-buffer

      # Display
      setw -g automatic-rename on
      set -g renumber-windows on
      set -g set-titles on
      set -g set-titles-string '#h  #S  #I #W'
      set -g display-panes-time 800
      set -g display-time 4000
      set -g status-interval 5
      set -g monitor-activity on
      set -g visual-activity off
      set -g pane-base-index 1

      # Log
      bind P pipe-pane -o "cat>>~/#W.log"\; display "Log on ~/#W.log"

      # TokyoNight theme
      set -g mode-style "fg=color4,bg=color8"
      set -g message-style "fg=color4,bg=color8"
      set -g message-command-style "fg=color4,bg=color8"
      set -g pane-border-style "fg=color8"
      set -g pane-active-border-style "fg=color4"
      set -g status "on"
      set -g status-justify "left"
      set -g status-style "fg=color4,bg=default"
      set -g status-left-length "100"
      set -g status-right-length "100"
      set -g status-left-style NONE
      set -g status-right-style NONE
      set -g status-left "#[fg=color0,bg=color13,bold] #S #[fg=color4,bg=default,nobold,nounderscore,noitalics]"
      set -g status-right "#[fg=color0,bg=default,nobold,nounderscore,noitalics] #[fg=color4,bg=default] #{prefix_highlight} #[fg=color8,bg=default,nobold,nounderscore,noitalics] #[fg=color4,bg=color8] %d-%m-%Y #[fg=color4,bg=default] #[fg=color4,bg=color8] %H:%M #[fg=color4,bg=default] #[fg=color0,bg=color4,bold] #h "
      setw -g window-status-activity-style "fg=color11,bg=default"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=color11,bg=default"
      setw -g window-status-format "#[bg=default,fg=color0,noitalics] #[bg=color8,fg=color4] #I ❯#[bg=color8,fg=color4] #{?window_zoomed_flag,#[fg=color9]❯,}#[bg=color8,fg=color4,bold]#W#[bg=color8,fg=color4,bold]#{?window_zoomed_flag,#[fg=color9]❮,} #[bg=default,fg=color0,noitalics]"
      setw -g window-status-current-format "#[bg=default,fg=color0,nobold,noitalics,nounderscore] #[bg=color6,fg=color0] #I ❯#[bg=color6,fg=color0,bold] #{?window_zoomed_flag,#[fg=color9]❯,}#[bg=color6,fg=color0,bold]#W#[bg=color6,fg=color0,bold]#{?window_zoomed_flag,#[fg=color9]❮,} #[bg=default,fg=color0,nobold,noitalics,nounderscore]"
      set -g @prefix_highlight_output_prefix "#[fg=color11]#[bg=default] #[fg=color0]#[bg=color11]"
      set -g @prefix_highlight_output_suffix " "
      set -g status-position bottom
    '';
  };
}
