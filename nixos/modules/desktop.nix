#/etc/nixos/modules/desktop.nix
# Desktop shell + Adwaita theming for the Hyprland session.
# The bar/notifications/quick-settings are a Quickshell config ("hyprshell",
# see ~/.config/quickshell/hyprshell, started with `qs -c hyprshell`).
# waybar and dunst are no longer used.
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Shell
    quickshell
    wofi
    cliphist
    libnotify
    jq
    xdg-utils

    # Theming (GNOME/libadwaita look)
    adw-gtk3
    adwaita-icon-theme
    gnome-themes-extra
    adwaita-qt6
    # adwaita-fonts would provide "Adwaita Sans"/"Adwaita Mono"; it is not in
    # every nixpkgs snapshot, so Cantarell + Inter are used as the HIG fonts.
    cantarell-fonts
    inter

    # Hyprland tools
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    hyprpicker
    grim
    slurp
    wl-clipboard
    wf-recorder
    brightnessctl
    playerctl
    pavucontrol
    gammastep
    networkmanager
    bluez

    # GNOME apps ("gnome but better")
    nautilus
    gnome-control-center
    gnome-system-monitor
    gnome-text-editor
    gnome-calculator
    loupe
    file-roller
  ];

  # --- Portals ---
  # programs.hyprland already adds xdg-desktop-portal-hyprland; the GTK portal
  # provides file chooser / settings (dark mode) / open-uri for every app.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config = {
      hyprland.default = ["hyprland" "gtk"];
      common.default = ["gtk"];
    };
  };

  # --- Fonts ---
  fonts.packages = with pkgs; [
    cantarell-fonts
    inter
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["Cantarell" "Inter"];
    monospace = ["JetBrainsMono Nerd Font"];
  };

  # --- GNOME-ish plumbing ---
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # hyprlock needs a PAM service to verify the password
  programs.hyprlock.enable = true;
  security.pam.services.hyprlock = {};

  # Qt follows the GNOME/Adwaita look
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };
}
