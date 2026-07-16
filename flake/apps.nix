{ nixpkgs, system, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
  };

  installLocal = pkgs.writeShellApplication {
    name = "install-local";

    runtimeInputs = with pkgs; [
      coreutils
      disko
      gnugrep
      gnused
      mkpasswd
      nix
      nixos-install-tools
      util-linux
    ];

    text = builtins.readFile ../scripts/install-local.sh;
  };
in
{
  ${system} = {
    install-local = {
      type = "app";
      program = "${installLocal}/bin/install-local";
    };
  };
}
