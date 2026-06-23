{
  config,
  pkgs,
  lib,
  ...
}: {
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
    signal-desktop
  ];
  xdg.desktopEntries.signal-desktop = {
    name = "Signal";
    exec = "signal-desktop --password-store=basic_text %U";
    icon = "signal-desktop";
    terminal = false;
    categories = ["Network" "InstantMessaging"];
    mimeType = ["x-scheme-handler/sgnl" "x-scheme-handler/signalcaptcha"];
  };
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

      # ls/grep colors reference kitty's wallust-themed ANSI palette by index
      # (not fixed RGB), so they track the wallpaper live like the rest of the
      # terminal. Regular files (fi) use the default foreground, which also
      # follows the wallpaper. di=green ex=orange-accent ln=cyan or/mi=red.
      set -gx LS_COLORS "di=01;38;5;2:fi=03:ln=01;38;5;6:or=01;38;5;1:mi=01;38;5;1:ex=01;38;5;8"
      set -gx GREP_COLORS "mt=01;38;5;8"

      function fish_prompt
        # Colors come from wallust (universal vars set by the wallpaper picker);
        # fall back to orange/light if they aren't set yet.
        set -l accent $wallust_accent
        set -l fg $wallust_fg
        test -z "$accent"; and set accent F08A3C
        test -z "$fg"; and set fg ECECE7

        set_color $fg
        printf '%s@%s ' $USER (hostname -s)

        set_color $accent
        printf '%s ' (prompt_pwd)

        set -l __fish_git_prompt_showupstream 0
        set -l __fish_git_prompt_use_informative_chars 1
        set -l __fish_git_prompt_char_dirtystate '✱'
        set -l __fish_git_prompt_color_branch $accent
        set -l __fish_git_prompt_color_dirty  $accent
        set -l __fish_git_prompt_color_clean  $accent
        printf '%s ' (fish_git_prompt)

        set_color $accent
        printf '> '
        set_color normal
      end

      function gpub --description "Push current branch and set upstream"
        set -l branch (git branch --show-current 2>/dev/null)
        if test -z "$branch"
          echo "Not on a git branch."
          return 1
        end
        git push --set-upstream origin $branch $argv
      end

      function git --wraps git --description "git wrapper with auto upstream push"
        if test (count $argv) -ge 1; and test "$argv[1]" = "push"
          if not contains -- --set-upstream $argv; and not contains -- -u $argv
            set -l branch (command git branch --show-current 2>/dev/null)
            if test -n "$branch"
              command git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>/dev/null
              if test $status -ne 0
                command git push --set-upstream origin $branch $argv[2..-1]
                return $status
              end
            end
          end
        end

        command git $argv
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
