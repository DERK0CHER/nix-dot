{pkgs, ...}: let
  pname = "zennotes";
  version = "2.2.0";

  src = pkgs.fetchurl {
    url = "https://github.com/ZenNotes/zennotes/releases/download/v${version}/ZenNotes-${version}-linux-x86_64.AppImage";
    hash = "sha256-9/amexk9rZlhs4RKndshO6hmRnmZV0t/e7qv9GWJVyI=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  zennotes = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm644 ${appimageContents}/ZenNotes.desktop \
        $out/share/applications/zennotes.desktop
      install -Dm644 ${appimageContents}/ZenNotes.png \
        $out/share/icons/hicolor/512x512/apps/zennotes.png
      substituteInPlace $out/share/applications/zennotes.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U' \
        --replace-fail 'Icon=ZenNotes' 'Icon=zennotes'
    '';
  };
in {
  environment.systemPackages = [zennotes];
}
