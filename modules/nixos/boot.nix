{ ... }:

{
  boot.loader = {
    timeout = 0;

    efi.canTouchEfiVariables = true;

    systemd-boot = {
      enable = true;
      configurationLimit = 5;
      editor = false;
    };
  };
}
