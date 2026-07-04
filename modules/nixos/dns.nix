{ ... }:

{
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
        "9.9.9.10"
      ];
    };
  };
}
