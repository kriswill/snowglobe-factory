{ pkgs, ... }:
let
  buildVimPlugin = pkgs.vimUtils.buildVimPlugin;
  fetchFromGitHub = pkgs.fetchFromGitHub;
in
{
  shellcheck-nvim = buildVimPlugin {
    pname = "shellcheck.nvim";
    version = "04.07.2025";
    src = fetchFromGitHub {
      owner = "pablos123";
      repo = "shellcheck.nvim";
      rev = "ee40e705ea61a4d790907c93cd01cc52480351fa";
      hash = "sha256-1rfEtD+II1uh6cn/dBxwGKxNFUwgoKXWtcJHIi6ydy4=";
    };
  };

  floaterm-vim = buildVimPlugin {
    pname = "floaterm.vim";
    version = "0-unstable";
    repo = "vim-floaterm";
    src = fetchFromGitHub {
      owner = "voldikss";
      repo = "vim-floaterm";
      rev = "7712701c5d20a0f9c935fbc2a6334083ce89b558";
      hash = "sha256-t9XI0REUPz3P0b7L6BPWIliU23uoETxeUtELCZiNIuE=";
    };
  };

  tuxedo-nvim = buildVimPlugin {
    pname = "tuxedo.nvim";
    version = "06.11.2026";
    src = fetchFromGitHub {
      owner = "iogamaster";
      repo = "tuxedo.nvim";
      rev = "65650b0ae3b1c3755a43306b07ada13bd78d47ac";
      hash = "sha256-e8Vk2QvMNDDpYCiTWwm5IgDlDhVKj2g+kNHpLbkYGx4=";
    };
  };
}
