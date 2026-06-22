#/etc/nixos/modules/hyprland.nix
{
  config,
  pkgs,
  ...
}: {
  # Session stack: GNOME + Hyprland + Niri
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;

  # Use GDM for Wayland sessions
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.niri.enable = true;

  # Essential desktop services
  services.dbus.enable = true;
  security.polkit.enable = true;

  # AMD Navi 44 (RX 9060 XT) + Hyprland 0.54.3 / aquamarine 0.10 workaround.
  # Atomic DRM commits fail (`atomic drm request: failed to commit: Invalid argument`)
  # and explicit sync trips `eglDupNativeFenceFDANDROID EGL_BAD_PARAMETER`, both
  # leading to SIGABRT in CFramebuffer::alloc / CHyprRenderer::renderMonitor.
  # AQ_NO_ATOMIC forces legacy DRM modesetting, bypassing both broken paths.
  # Must be set before Hyprland starts (aquamarine reads it at backend init),
  # so it lives here rather than in hypr/hyprland/env.conf.
  environment.sessionVariables.AQ_NO_ATOMIC = "1";
}
