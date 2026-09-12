{
  nixpkgs-stable,
  final,
  prev,
}:
{
  # ran into this: https://github.com/j-evins/glabels-qt/issues/256
  # the current nixpkgs version is very old for some reason.
  glabels-qt = prev.glabels-qt.overrideAttrs (old: {
    version = "unstable-2026-05-24";
    src = prev.fetchFromGitHub {
      owner = "j-evins";
      repo = "glabels-qt";
      tag = "3.99-master638";
      hash = "sha256-oi9WOzt3o+5QpfHeosCnbvDmLirE7jXaQUJ5ADd3LY4=";
    };
  });

  ani-cli = prev.ani-cli.overrideAttrs (old: {
    version = "5.1";
    src = prev.fetchFromGitHub {
      owner = "pystardust";
      repo = "ani-cli";
      tag = "v5.1";
      hash = "sha256-lPQA3iO3F/9NS2IziQccsJ3aai6WMQy6YObdB3mDCZA=";
    };
  });

  # python314 = prev.python314.override {
  #   packageOverrides = pyfinal: pyprev: {
  #     sip = pyprev.sip.overrideAttrs (old: {
  #       patches = [
  #         (prev.fetchpatch {
  #           name = "legacy-api-binding-fix.patch";
  #           url = "https://github.com/Python-SIP/sip/commit/09598895c607f3e41f0249ade217ace0a4da6437.patch";
  #           hash = "sha256-v0YeHyg0ymB0v32gpVRbMBIUk9U2etjs93VuOGPGg2M=";
  #         })
  #       ];
  #     });
  #   };
  # };

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
