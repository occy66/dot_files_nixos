{ config, pkgs, ... }:
{
  imports = [ /etc/nixos/hardware-configuration.nix ];

  # Boot: systemd-boot on EFI; canTouchEfiVariables lets the loader update the EFI boot entry.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "NIXOCCY";
  networking.networkmanager.enable = true;

  # Italian locale for time formatting and number separators.
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
  };

  # Display manager: dms-greeter (DankMaterialShell) remembers the last session per user by default.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/andrea";
  };
  # Registers gnome-keyring's D-Bus service (org.freedesktop.secrets) so apps like VSCode/Brave
  # can find a Secret Service to store credentials in non-GNOME sessions.
  services.gnome.gnome-keyring.enable = true;
  # Unlock the GNOME keyring on login via greetd PAM.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # gnome-shell's lock screen hardcodes the PAM service name "gdm-password" to authenticate
  # unlocking, regardless of which display manager started the session. Since we use
  # dms-greeter (not GDM), that PAM file doesn't exist and unlocking fails. This mirrors
  # exactly what NixOS's gdm module generates for that service, so the GNOME session's
  # screen lock works the same way it would under real GDM.
  security.pam.services.gdm-password = {
    text = ''
      auth substack login
      account include login
      password substack login
      session include login
    '';
  };

  # Hyprland — available as an alternative session alongside dms-greeter.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Niri — scrollable-tiling compositor, available as an alternative session alongside
  # Hyprland/Sway/GNOME at the dms-greeter session picker. Registers its own .desktop file
  # via services.displayManager.sessionPackages; dms-greeter's own compositor.name above
  # only controls what the login screen itself runs under, not the chosen session.
  programs.niri.enable = true;

  # Enables Sway system-wide with the GTK wrapper (needed for GTK file dialogs, app theming).
  # Extra packages are Wayland utilities that don't fit in home.packages (they need system-level access).
  # programs.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true;
  #   extraPackages = with pkgs; [
  #     swaylock
  #     swayidle
  #     wdisplays   # GUI monitor layout tool (identify output names for sway output config)
  #     grim        # Wayland screenshot
  #     slurp       # Region selector (used by grimshot)
  #     sway-contrib.grimshot
  #     wl-clipboard
  #     cliphist    # Clipboard history daemon
  #   ];
  # };

  # DankMaterialShell — Sway shell/widget layer providing bar, spotlight, clipboard, and audio IPC.
  programs.dms-shell = {
    enable = true;
    systemd = {
      enable = true;
      # Restart the dms systemd service automatically when the NixOS config changes.
      restartIfChanged = true;
    };
    enableClipboardPaste = true;
    enableSystemMonitoring = true;
    # Audio wavelength visualiser disabled (no use case on desktop).
    enableAudioWavelength = false;
  };

  # XDG portals: hyprland per Hyprland, gtk per file picker.
  # wlr.enable era per Sway (screen sharing) — commentato insieme a programs.sway.
  xdg.portal = {
    enable = true;
    # wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };

  # GNOME — available as an additional session for other users alongside Sway/Hyprland.
  services.desktopManager.gnome.enable = true;

  # OpenGL/Vulkan/VAAPI driver stack (Mesa) — never enabled before, defaults to false on NixOS.
  # Needed for GPU-accelerated rendering in GNOME (mutter) and Chromium-based browsers (Brave),
  # which otherwise crash (SIGSEGV) when they try to init hardware video decode/GL without it.
  # intel-media-driver covers this laptop's Intel Iris Xe (Alder Lake-P, Broadwell+ VAAPI).
  # hardware.graphics = {
  #   enable = true;
  #   extraPackages = with pkgs; [ intel-media-driver ];
  # };

  # rtkit grants real-time scheduling priority to PipeWire, preventing audio glitches.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # 32-bit ALSA support is needed for Wine and older games.
    alsa.support32Bit = true;
    # PulseAudio compatibility layer so apps that use libpulse still work.
    pulse.enable = true;
  };

  # Remove these two lines if the desktop board has no Bluetooth chip.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.upower.enable = true;

  # FortiClient VPN (IPsec/SSL with SAML SSO) — https://github.com/jplana/forticlient-nixos
  # gnome-keyring itself and its greetd PAM unlock are already configured above
  # (services.gnome.gnome-keyring.enable / security.pam.services.greetd.enableGnomeKeyring),
  # so this only needs to point the module's own keyring wiring at the same "greetd" PAM
  # service — it's a harmless duplicate of the enableGnomeKeyring = true set above.
  services.forticlient = {
    enable = true;
    gnomeKeyring.pamServices = [ "login" "greetd" ];
  };

  # AnyDesk: remote desktop daemon (unattended access).
  # No NixOS module exists for anydesk; run the daemon via a plain systemd service.
  systemd.services.anydesk = {
    description = "AnyDesk remote desktop daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.anydesk}/bin/anydesk --service";
      Restart = "on-failure";
    };
  };

  # Primary user account.
  users.users.andrea = {
    isNormalUser = true;
    description = "Andrea";
    extraGroups = [
      "wheel"        # sudo
      "networkmanager"
      "audio"
      "video"
      "docker"
      "lp"           # printing
      "lpadmin"      # manage printers via CUPS web UI
      "input"        # raw input device access (needed by some Wayland tools)
      "plugdev"      # unprivileged USB device access via udisks2
    ];
    shell = pkgs.zsh;
  };

  # users.users.nuovoutente = {
  #   isNormalUser = true;
  #   description = "NuovoUtente";
  #   extraGroups = [ "networkmanager" "audio" "video" ];
  # };

  # Must be true so the zsh module generates /etc/zshrc and zsh is available system-wide.
  programs.zsh.enable = true;

  # 1Password: CLI + GUI with polkit integration so the GUI can authenticate privileged operations.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Grants andrea the polkit policy that lets 1Password GUI unlock the SSH agent.
    polkitPolicyOwners = [ "andrea" ];
  };

  # nix-ld provides a stub dynamic linker at /lib64/ld-linux-x86-64.so.2 so pre-built
  # generic-linux binaries (e.g. gh copilot, node, etc.) can find glibc and friends.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      zlib
      curl
    ];
  };

  virtualisation.docker.enable = true;

  # Local PostgreSQL for devenv projects. mkOverride 10 wins over the default priority (1000),
  # replacing pg_hba.conf with a fully-trusted local config so devenv doesn't need passwords.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE  USER  ADDRESS       METHOD
      local   all       all                 trust
      host    all       all   127.0.0.1/32  trust
      host    all       all   ::1/128       trust
    '';
    ensureUsers = [
      {
        name = "andrea";
        # Superuser role lets devenv projects create/drop databases without extra grants.
        ensureClauses.superuser = true;
      }
    ];
  };

  # SSH server with password auth disabled; key-only access enforced.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "andrea" ];
    };
  };

  # Bans IPs after repeated failed SSH login attempts.
  services.fail2ban.enable = true;

  # NTP via Italian national time institute (INRIM) servers.
  services.ntp = {
    enable = true;
    servers = [ "ntp1.inrim.it" "ntp2.inrim.it" ];
  };

  # CUPS printing with foomatic-db for generic PostScript/PCL driver support.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.foomatic-db ];

  # Avahi enables mDNS (.local hostnames) and automatic printer discovery for CUPS.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # udisks2 is the system daemon that lets unprivileged users mount removable drives.
  # udiskie (started per-user by home-manager) calls udisks2 for automounting.
  services.udisks2.enable = true;

  # gvfs provides trash, network shares (SMB/WebDAV), and MTP (Android) to Nautilus.
  services.gvfs.enable = true;

  # Required for GTK theme/font/cursor settings to persist across sessions.
  programs.dconf.enable = true;

  # power-profiles-daemon switches between power-saver/balanced/performance on D-Bus.
  services.power-profiles-daemon.enable = true;

  # Lascia che Hyprland gestisca il lid switch via bindl (switch:on/off:Lid Switch).
  # Senza questo, logind sospende il sistema prima che Hyprland possa disabilitare eDP-1.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Polkit is required by 1Password GUI and various Wayland/system tools.
  security.polkit.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.symbols-only    # Icon-only font for terminals
      nerd-fonts.jetbrains-mono  # Primary coding font with Nerd Font icons
      victor-mono                # Cursive italic alternative
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font Mono" "JetBrains Mono" ];
        sansSerif = [ "Noto Sans" ];
        serif     = [ "Noto Serif" ];
        emoji     = [ "Noto Color Emoji" ];
      };
      hinting = {
        enable = true;
        # "slight" hinting improves sharpness without distorting letterforms.
        style = "slight";
      };
      antialias = true;
      # RGB subpixel order matches standard LCD panels; improves text clarity.
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";
    };
  };

  environment.systemPackages = with pkgs; [
    # App desktop condivise tra tutti gli utenti
    wget
    curl
    git
    brightnessctl  # Laptop backlight control (used by dms brightness IPC keybindings)
    wl-clipboard
    pamixer             # PulseAudio/PipeWire volume control (used by keybindings)
    brave
    zen-browser
    google-chrome
    vlc
    xournalpp
    papirus-icon-theme
    libreoffice
    gimp
    inkscape
    filezilla
    remmina
    system-config-printer
    ghostty
    anydesk
    spotify
  ];

  # Italian keyboard layout; second variant "nodeadkeys" gives a US-style layout as an alt.
  # grp:alt_shift_toggle switches between the two layouts.
  services.xserver.xkb = {
    layout = "it,it";
    variant = ",nodeadkeys";
    options = "grp:alt_shift_toggle";
  };
  console.keyMap = "it";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "andrea" ];
      # Binary caches for nixpkgs, devenv, and nix-community (neovim nightly, etc.).
      substituters = [
        "https://cache.nixos.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--keep-last 3 --delete-old";
    };
  };

  # NixOS ships /bin/sh but not /bin/bash; some third-party scripts hardcode #!/bin/bash.
  system.activationScripts.binbash = {
    text = "ln -sf ${pkgs.bash}/bin/bash /bin/bash";
    deps = [ ];
  };

  system.activationScripts.gdm-faces = {
    text = ''
      for user in andrea; do
        src="/home/$user/.face"
        if [ -f "$src" ]; then
          install -Dm644 "$src" "/var/lib/AccountsService/icons/$user"
          dest="/var/lib/AccountsService/users/$user"
          mkdir -p /var/lib/AccountsService/users
          if [ ! -f "$dest" ]; then
            printf '[User]\nIcon=/var/lib/AccountsService/icons/%s\n' "$user" > "$dest"
          else
            # Update only the Icon= line, preserving Session= and other keys written by GDM
            if ${pkgs.gnugrep}/bin/grep -q '^Icon=' "$dest"; then
              ${pkgs.gnused}/bin/sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$user|" "$dest"
            else
              ${pkgs.gnused}/bin/sed -i '/^\[User\]/a '"Icon=/var/lib/AccountsService/icons/$user" "$dest"
            fi
          fi
        fi
      done
    '';
  };

  system.stateVersion = "26.05";
}
