# nixos/modules/gaming.nix — gaming stack for AMD Ryzen 7 + Radeon RX 9060 XT
# (RDNA4, amdgpu/RADV). Imported from configuration.nix.
#
# Pairs with hypr/scripts/game-mode (compositor + focus + priority toggle)
# and hypr/hyprland/gaming.conf (window/workspace rules).
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Feral GameMode: CPU governor, renice, GPU perf level while a game runs.
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # Gamescope micro-compositor (used by `game-mode run --exclusive`).
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    remotePlay.openFirewall = false;
  };
  hardware.steam-hardware.enable = true;

  # power-profiles-daemon: game-mode switches performance <-> balanced.
  services.power-profiles-daemon.enable = true;

  # sched_ext scheduler (needs kernel >= 6.12 with sched_ext; the default
  # NixOS unstable kernel qualifies). scx_lavd is the gaming-oriented,
  # latency-criticality aware scheduler.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  boot.kernel.sysctl = {
    # Some games / Proton titles need many mappings (Steam recommends this).
    "vm.max_map_count" = 2147483642;
    # Split-lock mitigation stalls some (Windows-origin) games badly.
    "kernel.split_lock_mitigate" = 0;
    # zram is cheap to swap to; be eager about it.
    "vm.swappiness" = 100;
  };

  # boot.nix already sets zramSwap.enable = true; only tune it here.
  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault 50;
    algorithm = lib.mkDefault "zstd";
  };

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    protontricks
    jq
    libnotify
  ];

  # Let hypr/scripts/game-mode raise game priority and pause ollama
  # without a password prompt.
  security.sudo.extraRules = [
    {
      users = ["beba"];
      commands = [
        {
          command = "${pkgs.util-linux}/bin/renice";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop ollama";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl start ollama";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  users.users.beba.extraGroups = lib.mkAfter ["gamemode"];
}
