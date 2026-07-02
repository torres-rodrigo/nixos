{ nixpkgs, system, ... }:

let
  pkgs = import nixpkgs {
    inherit system;
  };
in
{
  ${system} = {
    default = pkgs.mkShell {
      packages = with pkgs; [
        nixfmt
        statix
        deadnix
      ];
    };
  };
}
