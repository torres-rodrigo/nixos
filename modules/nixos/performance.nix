{ ... }:

{
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
    "kernel.perf_event_paranoid" = 1;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_fastopen" = 3;
  };

  services.irqbalance.enable = true;
}
