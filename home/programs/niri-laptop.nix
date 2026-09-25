{ pkgs, lib, ... }:
let
  # niri manages eDP-1 on/off on lid events natively (unlike Hyprland, no script needed
  # for that part — see switch-events below). This only covers what niri can't do itself:
  # suspending when the lid closes with no external monitor picking up the display,
  # mirroring hyprLidSuspendIfAlone in hyprland-laptop.nix but reading niri's own runtime
  # state via `niri msg -j outputs` instead of a script-maintained state file.
  niriLidSuspendIfAlone = pkgs.writeShellScript "niri-lid-suspend-if-alone" ''
    set -uo pipefail
    other_monitor_active() {
      niri msg -j outputs | jq -e \
        'to_entries | any(.[]; .key != "eDP-1" and .value.logical != null)' >/dev/null
    }
    other_monitor_active || systemctl suspend
  '';
in
{
  # Force-overwrite config.kdl if it already exists unmanaged (same rationale as
  # hyprland-laptop.nix's xdg.configFile."hypr/hyprland.conf".force).
  xdg.configFile."niri/config.kdl".force = true;
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "it,it"
                variant ",nodeadkeys"
                options "grp:alt_shift_toggle"
            }
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    // Only eDP-1 needs an explicit block (scale); any external monitor is left
    // unlisted so niri auto-configures it (preferred mode, scale 1, auto position) —
    // the same effect as Hyprland's ",preferred,auto,1" wildcard fallback.
    output "eDP-1" {
        scale 1.25
    }

    layout {
        gaps 5

        // Hyprland used a single always-visible border; niri splits that into two
        // independent layers (focus-ring = active-window highlight, border = always
        // visible). Disabling focus-ring and using border alone is the closer match.
        focus-ring {
            off
        }
        border {
            width 4
            active-color "#7aa2f7"
            inactive-color "#595959"
        }
    }

    // niri has no layout-level corner rounding; it's applied per window via a
    // rule with no match block, i.e. it applies to every window.
    window-rule {
        geometry-corner-radius 8
        clip-to-geometry true
    }

    window-rule {
        match app-id="org.gnome.Calculator"
        open-floating true
    }
    window-rule {
        match title="^About.*$"
        open-floating true
    }
    window-rule {
        match title="^pop-up$"
        open-floating true
    }
    window-rule {
        match app-id="com.mitchellh.ghostty"
        open-on-workspace "2"
    }
    window-rule {
        match app-id="brave-browser"
        open-on-workspace "3"
    }
    window-rule {
        match app-id="Spotify"
        open-on-workspace "9"
    }

    // niri hot-reloads config.kdl on save — no reload bind needed (unlike Hyprland's
    // SUPER SHIFT C -> hyprctl reload).
    binds {
        // Focus: niri's model is columns (horizontal) vs windows within a column
        // (vertical), unlike Hyprland's uniform 4-direction movefocus.
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }
        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }

        Mod+Shift+H     { move-column-left; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Right { move-column-right; }

        // Layout — F is real fullscreen, S is the closer analog to Hyprland's
        // "fake fullscreen" (fullscreen, 1): fills the column without hiding the bar.
        Mod+F           { fullscreen-window; }
        Mod+S           { maximize-column; }
        Mod+Shift+Space { toggle-window-floating; }
        // Hyprland's SUPER E (togglesplit) and SUPER TAB/SHIFT+TAB (tab groups) have
        // no equivalent in niri's scrolling-column model — intentionally dropped.
        Mod+R repeat=false { switch-preset-column-width; }

        // System
        Mod+Return      { spawn "ghostty"; }
        Mod+N           { spawn "nautilus"; }
        Mod+C           { spawn "brave"; }
        Mod+Shift+Q     { close-window; }
        Mod+Shift+E { quit skip-confirmation=true; }

        // DankMaterialShell — stessi ipc call di hyprland-laptop.nix/sway-laptop.nix
        Mod+Space       { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
        Mod+V           { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
        Mod+M           { spawn "dms" "ipc" "call" "processlist" "focusOrToggle"; }
        Mod+Comma       { spawn "dms" "ipc" "call" "settings" "focusOrToggle"; }

        // Lock screen — Mod+Shift+L is already move-column-right above (matches
        // Hyprland's own config, where the same key combo is bound twice); moved here.
        Mod+Shift+Escape { spawn "dms" "ipc" "call" "lock" "lock"; }

        // 1Password quick access
        Ctrl+Shift+Space { spawn "1password" "--quick-access"; }

        // Screenshot — niri's built-in interactive UI replaces grim/slurp entirely.
        Print       { screenshot; }
        Mod+Alt+Print { screenshot-screen; }
        Alt+Print   { screenshot-window; }

        // Tasti speciali tastiera
        XF86HomePage  { spawn "brave"; }
        XF86Explorer  { spawn "nautilus"; }
        XF86Calculator { spawn "gnome-calculator"; }

        // Workspace — niri workspaces are dynamic/per-monitor; fixed 1-10 indices are
        // "best effort" (see Configuration:-Key-Bindings) but behave the same as
        // Hyprland's fixed grid in practice for this use case.
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }

        // Audio e luminosità via dms (speculare a hyprland-laptop.nix/sway-laptop.nix)
        XF86AudioRaiseVolume      { spawn "dms" "ipc" "call" "audio" "increment" "3"; }
        XF86AudioLowerVolume      { spawn "dms" "ipc" "call" "audio" "decrement" "3"; }
        XF86MonBrightnessUp       { spawn "dms" "ipc" "call" "brightness" "increment" "5"; }
        XF86MonBrightnessDown     { spawn "dms" "ipc" "call" "brightness" "decrement" "5"; }
        XF86AudioMute             { spawn "dms" "ipc" "call" "audio" "mute"; }
    }

    // Lid switch: niri already disables/enables eDP-1 natively on lid events (see the
    // note in Configuration:-Switch-Events), so unlike hyprLidSync this only needs to
    // handle what niri doesn't: locking, and suspending when no external monitor is
    // picking up the display.
    switch-events {
        lid-close {
            spawn "bash" "-c" "dms ipc call lock lock; ${niriLidSuspendIfAlone}"
        }
    }

    spawn-at-startup "syncthing" "serve" "--no-browser" "--logfile=default"
    spawn-sh-at-startup "wl-paste --watch cliphist store"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
    // niri honours XDG autostart, but forticlient-tray is kept explicit here for
    // parity with hyprland-laptop.nix's exec-once (which needs it, since Hyprland
    // doesn't honour XDG autostart).
    spawn-at-startup "forticlient-tray"
  '';
}
