{ pkgs, lib, ... }:
let
  # Sincronizza lo stato di eDP-1 (attivo/disabilitato) in base a coperchio + monitor
  # esterni rilevati via /sys/class/drm — non tramite `hyprctl monitors`, che a volte
  # non ha ancora negoziato i monitor esterni nei primi secondi dopo l'avvio.
  # Lo stato desiderato viene scritto in monitors-dynamic.conf (sourced dal config
  # sotto) e applicato con `hyprctl reload`, così sopravvive a reload successivi
  # (es. innescati da dms/matugen), a differenza di un semplice `hyprctl keyword`.
  hyprLidSync = pkgs.writeShellScript "hypr-lid-sync" ''
    set -uo pipefail

    STATE_DIR="$HOME/.local/state/hypr"
    DYNAMIC_CONF="$STATE_DIR/monitors-dynamic.conf"
    mkdir -p "$STATE_DIR"

    external_connected() {
      for status in /sys/class/drm/card*-*/status; do
        [ -e "$status" ] || continue
        case "$status" in
          *-eDP-*) continue ;;
        esac
        [ "$(cat "$status")" = "connected" ] && return 0
      done
      return 1
    }

    lid_closed() {
      for state in /proc/acpi/button/lid/*/state; do
        [ -r "$state" ] || continue
        grep -q closed "$state" && return 0
      done
      return 1
    }

    # Un output "connected" in /sys/class/drm è solo un rilevamento elettrico:
    # non garantisce che Hyprland lo abbia già negoziato e attivato. Prima di
    # spegnere eDP-1 verifichiamo che esista già un altro monitor DAVVERO
    # attivo secondo Hyprland stesso — altrimenti si rischia di restare senza
    # nessun output (dms crasha con "no outputs" e la sessione si blocca).
    other_monitor_active() {
      hyprctl monitors 2>/dev/null | grep '^Monitor' | grep -qv 'eDP-1'
    }

    if lid_closed && external_connected && other_monitor_active; then
      desired='monitor = eDP-1,disable'
    else
      desired='monitor = eDP-1,preferred,auto,1.25'
    fi

    current=""
    [ -f "$DYNAMIC_CONF" ] && current=$(cat "$DYNAMIC_CONF")

    if [ "$current" != "$desired" ]; then
      echo "$desired" > "$DYNAMIC_CONF"
      hyprctl reload >/dev/null 2>&1

      if [ "$desired" = 'monitor = eDP-1,disable' ]; then
        hyprctl dispatch focusmonitor DP-3 >/dev/null 2>&1
        hyprctl dispatch moveworkspacetomonitor 1 DP-3 >/dev/null 2>&1
      else
        hyprctl dispatch moveworkspacetomonitor 1 eDP-1 >/dev/null 2>&1
      fi
    fi
  '';

  # Sospende il sistema alla chiusura del coperchio, ma solo se eDP-1 è rimasto lo
  # stato desiderato (cioè NON c'è un monitor esterno che ha preso il suo posto).
  # Va chiamato DOPO hyprLidSync, che scrive lo stato aggiornato in monitors-dynamic.conf.
  hyprLidSuspendIfAlone = pkgs.writeShellScript "hypr-lid-suspend-if-alone" ''
    set -uo pipefail
    DYNAMIC_CONF="$HOME/.local/state/hypr/monitors-dynamic.conf"
    grep -q disable "$DYNAMIC_CONF" 2>/dev/null || systemctl suspend
  '';

  # Sync iniziale + ascolto eventi Hyprland (monitor aggiunto/rimosso) al posto di
  # un timeout fisso: reagisce a quando i monitor esterni compaiono davvero,
  # con qualche re-sync ritardato per assorbire negoziazioni lente (dock/hub).
  hyprLidWatch = pkgs.writeShellScript "hypr-lid-watch" ''
    set -uo pipefail

    ${hyprLidSync}
    touch /tmp/hypr-monitor-init-done

    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$SOCKET" | while read -r event; do
      case "$event" in
        monitoradded*|monitorremoved*)
          ( sleep 1; ${hyprLidSync}; sleep 2; ${hyprLidSync}; sleep 4; ${hyprLidSync} ) &
          ;;
      esac
    done
  '';
in
{
  # Force-overwrite hyprland.conf se esiste già come file non gestito da HM.
  xdg.configFile."hypr/hyprland.conf".force = true;

  # monitors-dynamic.conf (sourced sotto) è scritto a runtime da hyprLidSync e viene
  # applicato da Hyprland in modo sincrono al parsing del config, PRIMA che l'exec-once
  # di hyprLidWatch possa risincronizzarlo con lo stato reale di coperchio/monitor
  # esterni. Un "disable" lasciato lì da una sessione precedente (es. ufficio, coperchio
  # chiuso) sopravvivrebbe quindi a un riavvio a freddo altrove, spegnendo l'unico
  # monitor del portatile prima ancora che lo script possa correggerlo (e mandando in
  # crash dms/quickshell per assenza di output). Per questo il default sicuro va
  # riscritto ad ogni activation, non solo se il file manca: hyprLidSync lo
  # ricalcolerà comunque correttamente non appena Hyprland è avviato.
  home.activation.hyprLidState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/state/hypr"
    echo 'monitor = eDP-1,preferred,auto,1.25' > "$HOME/.local/state/hypr/monitors-dynamic.conf"
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    configType = "hyprlang";
    # Di default home-manager sposta le righe "source" in cima al file generato.
    # Qui serve l'opposto: monitors-dynamic.conf (sourced in settings.source
    # sotto) deve stare DOPO la lista statica "monitor" perché la sua regola
    # per eDP-1 vinca.
    sourceFirst = false;

    settings = {
      # Laptop monitor layout.
      # Schermo interno a 1.25x; qualunque monitor esterno collegato (ufficio,
      # cliente, ecc.) viene gestito in automatico dal fallback sotto.
      monitor = [
        # Fallback per qualunque monitor esterno collegato: auto.
        ",preferred,auto,1"

        "eDP-1,preferred,auto,1.25"
      ];

      # Stato dinamico di eDP-1 (attivo/disabilitato), gestito da hyprLidSync.
      # Va DOPO la lista statica sopra così la sua regola per eDP-1 vince.
      source = "~/.local/state/hypr/monitors-dynamic.conf";

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 4;
        "col.active_border" = "rgba(7aa2f7ff)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        bezier = "ease, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, ease"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 8, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "it,it";
        kb_variant = ",nodeadkeys";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      # dms viene avviato dal suo servizio systemd (programs.dms-shell.systemd.enable = true).
      "exec-once" = [
        "rm -f /tmp/hypr-monitor-init-done"
        "syncthing serve --no-browser --logfile=default"
        "wl-paste --watch cliphist store"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        # Hyprland doesn't honour XDG autostart (services.forticlient.trayAutostart's
        # /etc/xdg/autostart entry), so the SAML-SSO tray needs an explicit exec-once.
        "forticlient-tray"
        # Sincronizza subito lo stato di eDP-1 in base al coperchio, poi resta in
        # ascolto per ri-sincronizzare quando i monitor esterni compaiono/spariscono
        # (vedi definizione di hyprLidWatch sopra). Il marker che crea evita che il
        # bind switch:on:Lid Switch (che scatta anche per la risincronizzazione
        # iniziale dello stato, non solo per una chiusura reale) richiami dms lock
        # durante l'avvio, causando doppia richiesta password.
        "${hyprLidWatch}"
      ];

      bind = [
        # Navigazione finestre (vim-style, speculare a sway-laptop.nix)
        "SUPER, H, movefocus, l"
        "SUPER, J, movefocus, d"
        "SUPER, K, movefocus, u"
        "SUPER, L, movefocus, r"
        "SUPER, left, movefocus, l"
        "SUPER, down, movefocus, d"
        "SUPER, up, movefocus, u"
        "SUPER, right, movefocus, r"

        # Spostamento finestre
        "SUPER SHIFT, H, movewindow, l"
        "SUPER SHIFT, J, movewindow, d"
        "SUPER SHIFT, K, movewindow, u"
        "SUPER SHIFT, L, movewindow, r"
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, down, movewindow, d"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, right, movewindow, r"

        # Layout
        "SUPER, F, fullscreen, 0"
        "SUPER SHIFT, SPACE, togglefloating,"
        "SUPER, E, layoutmsg, togglesplit"
        "SUPER, S, fullscreen, 1"
        "SUPER, TAB, changegroupactive, f"
        "SUPER SHIFT, TAB, changegroupactive, b"
        "SUPER, R, submap, resize"

        # Azioni sistema
        "SUPER, RETURN, exec, ghostty"
        "SUPER, N, exec, nautilus"
        "SUPER, C, exec, brave"
        "SUPER SHIFT, Q, killactive,"
        "SUPER SHIFT, C, exec, hyprctl reload"
        "SUPER SHIFT, E, exit,"

        # DankMaterialShell — stesse chiamate di sway-laptop.nix
        "SUPER, SPACE, exec, dms ipc call spotlight toggle"
        "SUPER, V, exec, dms ipc call clipboard toggle"
        "SUPER, M, exec, dms ipc call processlist focusOrToggle"
        "SUPER, comma, exec, dms ipc call settings focusOrToggle"

        # Lock screen
        "SUPER SHIFT, L, exec, dms ipc call lock lock"

        # 1Password quick access
        "CTRL SHIFT, SPACE, exec, 1password --quick-access"

        # Screenshot → clipboard
        "SUPER, P, exec, grim -g \"$(slurp -d)\" - | wl-copy"
        "SUPER SHIFT, P, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SUPER ALT, P, exec, grim - | wl-copy"

        # Screenshot → file ~/Pictures/Screenshots/ (+ copia in clipboard)
        "SUPER SHIFT, S, exec, bash -c 'mkdir -p ~/Pictures/Screenshots; F=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png; grimshot save area \"$F\" && wl-copy < \"$F\"'"
        "SUPER CTRL, S, exec, bash -c 'mkdir -p ~/Pictures/Screenshots; F=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png; grim \"$F\" && wl-copy < \"$F\"'"

        # Tasti speciali tastiera
        ", XF86HomePage, exec, brave"
        ", XF86Explorer, exec, nautilus"
        ", XF86Calculator, exec, gnome-calculator"

        # Workspace
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"
      ];

      # Mouse: drag floating con Mod+click-sx, resize con Mod+click-dx
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Audio e luminosità via dms (speculare a sway-laptop.nix)
      bindel = [
        ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
        ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
        ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
        ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
      ];

      bindl = [
        ", XF86AudioMute, exec, dms ipc call audio mute"
        # Lid switch: hyprLidSync applica/disapplica eDP-1 (idempotente, sopravvive a
        # reload). Il lock va DOPO il sync per evitare che la sua surface finisca su
        # un monitor che sta per spegnersi. Il guard sul marker ignora l'evento se lo
        # script di avvio non ha ancora finito: Hyprland rilancia switch:on anche solo
        # per risincronizzare lo stato corrente all'avvio, non solo per una chiusura
        # reale, e senza questo guard chiederebbe la password due volte. Dopo il lock,
        # sospende il sistema SOLO se non c'è un monitor esterno attivo a fare da display
        # (altrimenti il coperchio chiuso col portatile in dock continuerebbe a sospendersi).
        ", switch:on:Lid Switch, exec, bash -c '${hyprLidSync}; [ -f /tmp/hypr-monitor-init-done ] || exit 0; dms ipc call lock lock; ${hyprLidSuspendIfAlone}'"
        ", switch:off:Lid Switch, exec, bash -c '[ -f /tmp/hypr-monitor-init-done ] || exit 0; ${hyprLidSync}'"
      ];

    };

    # Submap resize — entra con SUPER+R, esci con Return o Escape
    extraConfig = ''
      hl.window_rule({ match = { class = "org.gnome.Calculator" }, float = true })
      hl.window_rule({ match = { title = ".*About.*" }, float = true })
      hl.window_rule({ match = { title = "pop-up" }, float = true })
      hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, workspace = "2 silent" })
      hl.window_rule({ match = { class = "brave-browser" }, workspace = "3 silent" })
      hl.window_rule({ match = { class = "Spotify" }, workspace = "9 silent" })

      submap = resize

      binde = , H, resizeactive, -10 0
      binde = , J, resizeactive, 0 10
      binde = , K, resizeactive, 0 -10
      binde = , L, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , down, resizeactive, 0 10
      binde = , up, resizeactive, 0 -10
      binde = , right, resizeactive, 10 0

      bind = , RETURN, submap, reset
      bind = , ESCAPE, submap, reset

      submap = reset
    '';
  };
}
