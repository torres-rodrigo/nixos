{ ... }:

{
  # Keep application delivery Nix-managed by default:
  # - no Flatpak
  # - no Snap
  # - no AppImage runtime helpers
  # Any exception should be explicit, documented, and easy to revert.
  services.flatpak.enable = false;
}
