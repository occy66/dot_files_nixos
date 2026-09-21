{ pkgs, config, ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    # wrapperFeatures.gtk = true per GTK3 apps (dialoghi file, etc.)
    wrapperFeatures.gtk = true;
    systemd.enable = true;

    config = {
      modifier = "Mod4";
      terminal = "ghostty";

      # Font per decorazioni finestre
      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size = 11.0;
      };

      # Gaps (stile minimalista)
      gaps = {
        inner = 5;
        outer = 5;
      };

      # Keybindings base (hjkl vim-style)
      keybindings =
        let mod = "Mod4"; in
        {
          # Navigazione finestre
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          # Spostamento finestre
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          # Layout
          "${mod}+b" = "splith";
          "${mod}+Shift+v" = "splitv";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+a" = "focus parent";
          "${mod}+r" = "mode resize";

          # Workspace
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+0" = "workspace number 10";
          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
          "${mod}+Shift+0" = "move container to workspace number 10";

          # Azioni sistema
          "${mod}+Return" = "exec ghostty";
          "${mod}+Shift+q" = "kill";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+e" = "exec swaynag -t warning -m 'Uscire da Sway?' -B 'Sì' 'swaymsg exit'";

          # Applicazioni
          "${mod}+n" = "exec nautilus";
          "${mod}+c" = "exec brave";

          # 1Password quick access
          "Ctrl+Shift+Space" = "exec 1password --quick-access";

          # Screenshot (grimshot)
          "Mod4+p" = "exec grimshot save active";
          "Mod4+Shift+p" = "exec grimshot save area";
          "Mod4+Mod1+p" = "exec grimshot save output";
          "Mod4+Ctrl+p" = "exec grimshot save window";

          # Tasti speciali tastiera
          "XF86HomePage" = "exec brave";
          "XF86Explorer" = "exec nautilus";
          "XF86Calculator" = "exec gnome-calculator";

          # DankMaterialShell (dms) keybindings
          "${mod}+space" = "exec dms ipc call spotlight toggle";
          "${mod}+v" = "exec dms ipc call clipboard toggle";
          "${mod}+m" = "exec dms ipc call processlist focusOrToggle";
          "${mod}+comma" = "exec dms ipc call settings focusOrToggle";

          # Audio via dms
          "XF86AudioRaiseVolume" = "exec dms ipc call audio increment 3";
          "XF86AudioLowerVolume" = "exec dms ipc call audio decrement 3";
          "XF86AudioMute" = "exec dms ipc call audio mute";

          # Luminosità via dms
          "XF86MonBrightnessUp" = "exec dms ipc call brightness increment 5";
          "XF86MonBrightnessDown" = "exec dms ipc call brightness decrement 5";
        };

      # Modalità resize
      modes = {
        resize = {
          "h" = "resize shrink width 10px";
          "j" = "resize grow height 10px";
          "k" = "resize shrink height 10px";
          "l" = "resize grow width 10px";
          "Left" = "resize shrink width 10px";
          "Down" = "resize grow height 10px";
          "Up" = "resize shrink height 10px";
          "Right" = "resize grow width 10px";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      # Laptop monitor layout. Run `wdisplays` or `swaymsg -t get_outputs` to identify output names.
      # Comment out external monitor entries if working without a dock.
      output = {
        "DP-3" = { pos = "0 0"; res = "1440x900"; transform = "270"; };
        "DP-4" = { pos = "900 0"; res = "1600x900"; };
        "DP-5" = { pos = "2500 0"; res = "1600x900"; };
      };

      workspaceOutputAssign = [
        { workspace = "1"; output = "eDP-1"; }
        { workspace = "2"; output = "DP-4"; }
        { workspace = "3"; output = "DP-5"; }
      ];

      # Auto-assign apps to workspaces on first launch (app_id is the Wayland app-id).
      assigns = {
        "2" = [{ app_id = "^com.mitchellh.ghostty$"; }];
        "3" = [{ app_id = "^brave-browser$"; }];
        "9" = [{ class = "^Spotify$"; }];
      };
      floating = {
        criteria = [
          { app_id = "org.gnome.Calculator"; }
          { window_role = "pop-up"; }
          { window_role = "About"; }
        ];
      };

      # Mod+left-click to drag floating windows; Mod+right-click to resize them.
      floating.modifier = "Mod4";

      # Services started once with Sway (always = false prevents re-launch on `sway reload`).
      startup = [
        # Syncthing started here rather than as a systemd service to keep it user-scoped.
        { command = "syncthing serve --no-browser --logfile=default"; always = false; }
        # Feeds Wayland clipboard events into cliphist for history access via Mod+v.
        { command = "wl-paste --watch cliphist store"; always = false; }
        # Polkit authentication agent: shows the password dialog for privileged operations.
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; always = false; }
        # dms is started by its own systemd service (programs.dms-shell.systemd.enable = true).
        # For manual startup instead: { command = "dms run"; always = false; }
      ];

      # Disable the built-in swaybar; DankMaterialShell provides its own bar via systemd.
      bars = [];

      # Input tastiera
      input = {
        "type:keyboard" = {
          xkb_layout = "it,it";
          xkb_variant = ",nodeadkeys";
          xkb_options = "grp:alt_shift_toggle,ctrl:nocaps";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          scroll_method = "two_finger";
        };
      };
    };

    # Configurazione extra non gestibile dal config attrset
    extraConfig = ''
      # Bordi finestre
      default_border pixel 4

      # Lid switch (laptop)
      set $laptop eDP-1
      bindswitch --reload --locked lid:on  output $laptop disable
      bindswitch --reload --locked lid:off output $laptop enable

      # Include configurazioni sway di sistema
      include /etc/sway/config.d/*
    '';
  };

  # Nota: le notifiche sono gestite da DankMaterialShell (dms).
  # Se dms non viene usato, abilitare mako:
  # services.mako = {
  #   enable = true;
  #   backgroundColor = "#16161e";
  #   borderColor = "#7aa2f7";
  #   textColor = "#c0caf5";
  #   borderRadius = 8;
  #   borderSize = 2;
  #   defaultTimeout = 5000;
  #   font = "JetBrainsMono Nerd Font 11";
  #   padding = "10,15";
  # };
}
