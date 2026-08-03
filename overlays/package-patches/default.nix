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

  # ani-cli from unstable is old and cannot download media
  ani-cli = prev.ani-cli.overrideAttrs (old: {
    version = "unstable-07-31-2026";
    src = prev.fetchFromGitHub {
      owner = "pystardust";
      repo = "ani-cli";
      rev = "38898bad8901106f7c8cabd8db1b7b26c620c32a";
      hash = "sha256-hhH66/1sq0v0O8mle9mK48dhfapBAGzwvX4HlZ1wFHU=";
    };

    runtimeInputs = old.runtimeInputs ++ [ prev.botan3 ];
  });

  # ceph doesn't build
  # https://github.com/NixOS/nixpkgs/issues/542206
  ceph =
    (prev.ceph.overrideScope (
      _: prev: {
        arrow-cpp = null;
        ceph = prev.ceph.overrideAttrs (
          {
            cmakeFlags ? [ ],
            ...
          }:
          {
            cmakeFlags = cmakeFlags ++ [
              (final.lib.cmakeBool "WITH_RADOSGW_SELECT_PARQUET" false)
              (final.lib.cmakeBool "WITH_RADOSGW_ARROW_FLIGHT" false)
            ];
          }
        );
      }
    )).ceph;

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
