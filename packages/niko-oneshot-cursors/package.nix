{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "niko-oneshot-cursors";
  src = builtins.fetchTarball {
    url = "https://www.earthgman.dev/assets/cursor-themes/niko-oneshot-cursors.tar.xz";
    sha256 = "sha256-DZ6uVIYgQDAXHpTtMiV3BAtWmA3lciHkzlvnjZ/piH0=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -r . $out/share/icons/niko-oneshot-cursors

    runHook postInstall
  '';
}
