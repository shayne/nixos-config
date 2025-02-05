{ pkgs, sources, ... }:
{
  programs.neovim = {
    enable = true;
    # TEMP: Disabled for now due to lua error on start
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs; [
      customVim.vim-copilot
      customVim.vim-cue
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-glsl
      customVim.vim-lastplace
      customVim.vim-misc
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.vim-zig
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-devicons
      customVim.vim-nord
      customVim.nvim-comment
      customVim.nvim-conform
      customVim.nvim-lspconfig
      customVim.nvim-plenary # required for telescope
      customVim.nvim-telescope
      customVim.nvim-treesitter
      customVim.nvim-treesitter-playground
      customVim.nvim-treesitter-textobjects

      vimPlugins.vim-airline
      vimPlugins.vim-airline-themes
      vimPlugins.vim-eunuch
      vimPlugins.vim-gitgutter

      vimPlugins.vim-markdown
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
      vimPlugins.vim-prettier
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };
}
