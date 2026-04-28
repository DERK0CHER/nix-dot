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
    wf-recorder
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
    package = pkgs.fish;
    shellInit = ''
      if test -z "$SSH_AUTH_SOCK"
        eval (ssh-agent -c) > /dev/null
      end
    '';
    interactiveShellInit = ''
      set fish_greeting

      if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
        cat ~/.cache/ags/user/generated/terminal/sequences.txt
      end

      set -g fish_color_command #ECECE7
      set -gx LS_COLORS "di=01;38;2;158;178;119:fi=03;38;2;222;216;192:ln=38;2;198;194;78:or=38;2;164;0;0:mi=38;2;164;0;0:ex=38;2;255;123;123"

      function fish_prompt
        set -l __salmon  '#ff7b7b'
        set -l __gold    '#ab8d2e'
        set -l __beige   '#ded8c0'

        set_color $__beige
        printf '%s@%s ' $USER (hostname -s)

        set_color $__gold
        printf '%s ' (prompt_pwd)

        set -l __fish_git_prompt_showupstream 0
        set -l __fish_git_prompt_use_informative_chars 1
        set -l __fish_git_prompt_char_dirtystate '✱'
        set -l __fish_git_prompt_color_branch $__gold
        set -l __fish_git_prompt_color_dirty  $__gold
        set -l __fish_git_prompt_color_clean  $__gold
        printf '%s ' (fish_git_prompt)

        set_color $__gold
        printf '> '
        set_color normal
      end
    '';
    shellAliases = {
      pamcan = "pacman";
      cl = "clear";
      wc = "wl-copy";
      nrs = "sudo nixos-rebuild switch";
      hms = "home-manager switch --flake ~/.config/home-manager#beba";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile = {
    "niri/config.kdl".source = ./.config/niri/config.kdl;
    "kitty/kitty.conf".source = ./.config/kitty/kitty.conf;
    "foot/foot.ini".text = ''
      [main]
      shell=/run/current-system/sw/bin/fish
    '';
    "nvim".source = ./.config/nvim;
    "fish/config.user.fish".source = ./.config/fish/config.fish;
    "fish/functions".source = ./.config/fish/functions;
    "fish/conf.d".source = ./.config/fish/conf.d;
  };
}
