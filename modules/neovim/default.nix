{ lib, pkgs, inputs, ... }:
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  xdg.configFile."nvim" = {
    source = ./lazyvim;
    recursive = true;
    force = true;
  };

  home.activation.lazyvimBackup = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    if [ -d "$HOME/.config/nvim/.git" ]; then
      backup="$HOME/.config/nvim.bak-$(date +%Y%m%d%H%M%S)"
      mv "$HOME/.config/nvim" "$backup"
      echo "Moved existing LazyVim checkout to $backup"
    fi
  '';
}
