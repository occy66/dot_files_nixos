{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Il lock screen è quello nativo di DMS (WlSessionLock + PAM), niente più hyprlock esterno.
        lock_cmd = "dms ipc call lock lock";
        before_sleep_cmd = "dms ipc call lock lock";
        after_sleep_cmd = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "dms ipc call lock lock";
        }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch dpms off 2>/dev/null; swaymsg 'output * dpms off' 2>/dev/null";
          on-resume = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null";
        }
      ];
    };
  };
}
