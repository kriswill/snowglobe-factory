{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  qt6,
  # Chromium runtime libraries (linked; patched in by autoPatchelfHook)
  glib,
  gdk-pixbuf,
  gtk3,
  nspr,
  nss,
  dbus,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cups,
  expat,
  libxcb,
  libxkbcommon,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  mesa,
  cairo,
  pango,
  systemd,
  alsa-lib,
  libdrm,
  # dlopen'd at runtime - supplied via the wrapper's LD_LIBRARY_PATH
  libGL,
  libva,
  pipewire,
  libpulseaudio,
}:

let
  version = "0.15.5.1";

  # nix system -> upstream asset suffix + tarball hash.
  # Refresh both hashes on every version bump:
  #   nix store prefetch-file --json <url> | jq -r .hash
  sources = {
    x86_64-linux = {
      suffix = "x86_64_linux";
      hash = "sha256-80oe4aarLjEJ2S45OVEqN8/mii8NIwtSXMFYn8GS/Zc=";
    };
    aarch64-linux = {
      suffix = "arm64_linux";
      hash = "sha256-2TI9B3GjdN5eWmZqfnVOIfKYwjjqwh345YaKx7X2TP4=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "helium: unsupported system ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation (finalAttrs: {
  pname = "helium";
  inherit version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-${source.suffix}.tar.xz";
    inherit (source) hash;
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    glib
    gdk-pixbuf
    gtk3
    nspr
    nss
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    expat
    libxcb
    libxkbcommon
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    mesa
    cairo
    pango
    systemd
    alsa-lib
    libdrm
    qt6.qtbase
  ];

  # Helium ships a Qt5 shim it never loads at runtime; we run against Qt6.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helium
    cp -r ./* $out/opt/helium/

    makeWrapper $out/opt/helium/helium-wrapper $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL libva pipewire libpulseaudio ]}" \
      --add-flags "--ozone-platform-hint=auto"

    install -Dm644 $out/opt/helium/helium.desktop \
      $out/share/applications/helium.desktop
    install -Dm644 $out/opt/helium/product_logo_256.png \
      $out/share/icons/hicolor/256x256/apps/helium.png

    runHook postInstall
  '';

  meta = {
    description = "Private, fast, and honest web browser (Chromium fork by imput)";
    homepage = "https://helium.computer";
    downloadPage = "https://github.com/imputnet/helium-linux/releases";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "helium";
    maintainers = [ lib.maintainers.EarthGman ];
  };
})
