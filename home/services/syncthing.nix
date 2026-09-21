{ ... }:
{
  # Syncthing runs as a user service (not system-level) so it has access to the user's home dir.
  # Folders and remote devices must be configured via the web UI at http://localhost:8384 after first boot.
  services.syncthing = {
    enable = true;
    # tray = false; # No tray icon — Sway has no native system tray (dms handles notifications).
  };
}
