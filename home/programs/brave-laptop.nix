{ ... }:
{
  # Brave's native Wayland Ozone backend segfaults on startup under GNOME/Mutter
  # (works fine under Hyprland/Sway). Forcing X11/XWayland via the .desktop entry
  # fixes launches from GNOME's app grid/Activities without touching the `exec brave`
  # keybinds in sway-laptop.nix/hyprland-laptop.nix, which call the binary directly
  # and keep running natively on Wayland there.
  #
  # TODO: workaround, remove this whole file (and the import in home-laptop.nix)
  # once a future Brave/Chromium or Mutter update fixes the native-Wayland crash.
  # Retest by running `brave` (no flags) from a GNOME session and checking
  # `coredumpctl list brave` for a fresh SIGSEGV.
  xdg.desktopEntries.brave-browser = {
    name = "Brave Web Browser";
    genericName = "Web Browser";
    comment = "Access the Internet";
    exec = "brave --ozone-platform=x11 %U";
    icon = "brave-browser";
    terminal = false;
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "application/pdf"
      "application/rdf+xml"
      "application/rss+xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/xml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/chromium"
    ];
    settings.StartupWMClass = "brave-browser";
    actions = {
      "new-window" = {
        name = "New Window";
        exec = "brave --ozone-platform=x11";
      };
      "new-private-window" = {
        name = "New Incognito Window";
        exec = "brave --ozone-platform=x11 --incognito";
      };
    };
  };
}
