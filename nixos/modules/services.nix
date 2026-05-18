#/etc/nixos/modules/services.nix
{ config, pkgs, ... }:

{

  # ZFS maintenance
  services.zfs.autoScrub.enable = true;

  # Enable SSH (optional)
   services.openssh.enable = true;

  # Enable CUPS for printing (optional)
   services.printing.enable = true;

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
  };

}

