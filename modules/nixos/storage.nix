{ ... }:

{
  boot.tmp.cleanOnBoot = true;

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
