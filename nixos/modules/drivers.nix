{ config, pkgs, ... }:

{
  # AMD/Mesa graphics stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
    ];
  };

  # AMD CPU/GPU scheduling and firmware defaults for Ryzen + RDNA cards.
  boot.kernelParams = [ "amd_pstate=active" ];
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  services.xserver.videoDrivers = [ "amdgpu" ];

}
