#/etc/nixos/modules/packages.nix
{
  config,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Calendar/agenda widget (theming-experiments)
    inputs.waylandar.packages.${pkgs.system}.default

    # Terminal & editor
    kitty
    claude-code
    lmstudio
    fastfetch
    neovim
    gnome-builder
    zathura
    vscodium
    gparted
    code-cursor
    chromium
    uxplay
    tor
    # Browser
    firefox
    tor-browser
    wireplumber
    pulseaudio
    flatpak
    texliveFull
    libreoffice-fresh

    # System utilities
    git
    curl
    btop
    nautilus
    feh
    gimp
    dunst
    libnotify

    ttfautohint

    # Communication
    discord
    vesktop
    thunderbird

    #Amenity
    spotify
    spotify-player
    spotify-cli-linux
    # Hyprland essentials
    waybar
    wofi
    dunst
    hyprshot
    hyprcursor
    hyprpaper
    # Wallpaper + colorscheme switching (theming-experiments)
    swww # runtime wallpaper daemon with transitions
    wallust # generate color palettes from wallpapers
    rofi # thumbnail wallpaper picker (wayland-capable)
    jq
    imagemagick # thumbnail generation
    slurp
    grim
    wl-clipboard
    wf-recorder # screen recording
    obs-studio
    swappy # screenshot annotation
    brightnessctl
    cliphist

    #dev stuff
    gcc
    clang
    meson
    gnumake
    nodejs
    glib
    qt6Packages.qt6ct
    pnpm

    # Node formatters
    prettier
    eslint_d

    # Python formatters
    black
    python3Packages.isort

    # Other formatters
    stylua
    shfmt
    clang-tools # for clang-format
    nixfmt
    alejandra
    gsettings-desktop-schemas
    pkgs.python313Packages.pylatexenc
    #garmin
    steam

    # Remote access
    wayvnc
  ];

  # Fonts for Hyprland
  fonts.packages = with pkgs; [
    fira-mono
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
    iosevka-comfy.comfy
    iosevka-comfy.comfy-motion
    iosevka-comfy.comfy-fixed
    iosevka
  ];
  programs.thunar.enable = true;
  programs.waybar.enable = true;

  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
}
