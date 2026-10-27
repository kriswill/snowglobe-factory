{
  nixpkgs-stable,
  final,
  prev,
}:
{
  # freetube = prev.freetube.overrideAttrs (old: rec {
  #   version = "0.25.3";
  #   src = prev.fetchFromGitHub {
  #     owner = "FreeTubeApp";
  #     repo = "Freetube";
  #     tag = "v0.25.3-beta";
  #     hash = "sha256-eaf10W8dBMJDlqOFd57hsqQqRcBOYAMavLrfmkuRbSw=";
  #   };
  #
  #   patches = [
  #     (prev.replaceVars ./freetube-build-script.patch {
  #       electron-version = prev.electron.version;
  #     })
  #     ./freetube-targets.patch
  #   ];
  #
  #   pnpmDeps = prev.fetchPnpmDeps {
  #     inherit (old) pname;
  #     inherit version src;
  #     pnpm = prev.pnpm_10;
  #     fetcherVersion = 4;
  #     hash = "sha256-rsgDxK6X2EzgPwIb9A9I+STkKI882i8jDuL4pO5kJHU=";
  #   };
  # });

	pywal16 = prev.callPackage ./pywal16.nix {  };

  # puddletag's icon is installed to the incorrect location
  # This causes some programs to display an empty icon entry
  puddletag = prev.puddletag.overrideAttrs (_: {
    postFixup = ''
      ICON_DIR=$out/share/icons/hicolor/256x256/apps
      mkdir -p $ICON_DIR
      mv $out/share/icons/puddletag.png $ICON_DIR
      wrapPythonPrograms
    '';
  });

  # fix the symlinks in zsh-syntax-highlighting
  zsh-syntax-highlighting = prev.zsh-syntax-highlighting.overrideAttrs {
    installPhase = ''
      PLUGIN_DIR="$out/share/zsh/plugins/zsh-syntax-highlighting"
      mkdir -p "$PLUGIN_DIR/highlighters"
      cp -r ./highlighters/* "$PLUGIN_DIR/highlighters"
      for link in $(find "$PLUGIN_DIR" -type l); do
        rm "$link"
      done

      install -D zsh-syntax-highlighting.plugin.zsh \
        "$PLUGIN_DIR/zsh-syntax-highlighting.plugin.zsh"
      install -D zsh-syntax-highlighting.zsh \
        "$PLUGIN_DIR/zsh-syntax-highlighting.zsh"
      install -D .revision-hash \
        "$PLUGIN_DIR/.revision-hash"
      install -D .version \
        "$PLUGIN_DIR/.version"

      ln -s "$PLUGIN_DIR" $out/share/zsh-syntax-highlighting
    '';
  };

  # give btop cuda and rocm support
  btop = prev.btop.override {
    rocmSupport = true;
    cudaSupport = true;
  };
}
