{ ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "America/Montevideo";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
