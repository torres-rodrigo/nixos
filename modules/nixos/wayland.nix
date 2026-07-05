{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.xwayland.enable = true;

  services.seatd.enable = true;

  xdg = {
    icons.enable = true;
    menus.enable = true;
    mime.enable = true;
    terminal-exec = {
      enable = true;
      settings.default = [
        "org.wezfurlong.wezterm.desktop"
      ];
    };

    portal = {
      enable = true;
      config.common.default = [
        "wlr"
        "gtk"
      ];
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      wlr.enable = true;
      xdgOpenUsePortal = true;
    };
  };

  environment = {
    sessionVariables = {
      GDK_BACKEND = "wayland,x11";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland,x11";
      XDG_SESSION_TYPE = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    systemPackages = with pkgs; [
      cliphist
      kdePackages.qtwayland
      libsForQt5.qt5.qtwayland
      wev
      wayland-utils
      wl-clip-persist
      wl-clipboard
      wlr-randr
    ];
  };
}
