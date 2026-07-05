{ pkgs, ... }:

let
  doomTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "doom-plymouth-theme";
    version = "1.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      themeDir="$out/share/plymouth/themes/doom"
      install -dm755 "$themeDir"

      install -m0644 ${../../assets/plymouth/bullet.png} "$themeDir/bullet.png"
      install -m0644 ${../../assets/plymouth/entry.png} "$themeDir/entry.png"
      install -m0644 ${../../assets/plymouth/lock.png} "$themeDir/lock.png"
      install -m0644 ${../../assets/plymouth/progress_bar.png} "$themeDir/progress_bar.png"
      install -m0644 ${../../assets/plymouth/progress_box.png} "$themeDir/progress_box.png"
      install -m0644 ${../../assets/plymouth/doom-logo.png} "$themeDir/doom-logo.png"
      install -m0644 ${../../assets/plymouth/doom.script} "$themeDir/doom.script"

      substitute ${../../assets/plymouth/doom.plymouth} "$themeDir/doom.plymouth" \
        --replace-fail @themedir@ "$themeDir"

      runHook postInstall
    '';
  };
in
{
  boot = {
    plymouth = {
      enable = true;
      theme = "doom";
      themePackages = [
        doomTheme
      ];
    };

    kernelParams = [
      "splash"
    ];
  };
}
