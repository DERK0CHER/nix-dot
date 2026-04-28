{ config, pkgs, lib, ... }:

{
  home.username = "beba";
  home.homeDirectory = "/home/beba";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bc
    brightnessctl
    cliphist
    easyeffects
    fcitx5
    foot
    fuzzel
    gammastep
    gnome-control-center
    gnome-system-monitor
    gnome-text-editor
    grim
    hyprland
    hyprpicker
    hyprshot
    jq
    libnotify
    nautilus
    neovim
    niri
    pavucontrol
    playerctl
    polkit_gnome
    slurp
    starship
    swappy
    awww
    wl-clipboard
    wlogout
    wofi
  ];

  home.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
    INPUT_METHOD = "fcitx";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${config.home.homeDirectory}/.local/state/ags/.venv";
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      pamcan = "pacman";
    };
    interactiveShellInit = ''
      source ~/.config/fish/config.user.fish

      function start-hyprland
        mkdir -p ~/.cache
        exec Hyprland > ~/.cache/hyprland.log 2>&1
      end

      function start-niri
        mkdir -p ~/.cache
        exec niri > ~/.cache/niri.log 2>&1
      end

      if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
      end

      if test -z "$DISPLAY"; and test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1; and set -q WAYLAND_AUTO_START
        switch "$WAYLAND_AUTO_START"
          case hyprland
            start-hyprland
          case niri
            start-niri
        end
      end
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile = {
    "hypr".source = ./.config/hypr;
    "niri/config.kdl".source = ./.config/niri/config.kdl;
    "kitty/kitty.conf".source = ./.config/kitty/kitty.conf;
    "nvim".source = ./.config/nvim;
    "fish/config.user.fish".source = ./.config/fish/config.fish;
    "fish/functions".source = ./.config/fish/functions;
    "fish/conf.d".source = ./.config/fish/conf.d;
  };
}
