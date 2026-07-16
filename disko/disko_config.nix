{ diskDevice }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = diskDevice;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/run/doom-disko-luks-password";
              extraFormatArgs = [ "--type luks2" "--pbkdf argon2id" ];
              extraOpenArgs = [
                "--allow-discards"
                "--perf-no_read_workqueue"
                "--perf-no_write_workqueue"
              ];
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" ];
                  };
                  "/var" = {
                    mountpoint = "/var";
                    mountOptions = [ "compress=zstd" "noatime" "ssd" ];
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "nodatacow" "noatime" "ssd" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
