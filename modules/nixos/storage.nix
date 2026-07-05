{ ... }:

{
  boot.tmp.cleanOnBoot = true;

  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
      interval = "monthly";
    };

    fstrim = {
      enable = true;
      interval = "weekly";
    };
  };
}
