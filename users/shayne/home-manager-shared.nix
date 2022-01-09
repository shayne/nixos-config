{ config, lib, pkgs, ... }:

let sources = import ../../nix/sources.nix; in {
  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.bat
    pkgs.exa
    pkgs.ripgrep
    pkgs.tealdeer
    pkgs.firefox
    pkgs.fzf
    pkgs.git-crypt
    pkgs.htop
    pkgs.jq
    # pkgs.rofi
    pkgs.go
    pkgs.gopls
    pkgs.tree
    pkgs.watch
    # pkgs.zathura

    # pkgs.tlaplusToolbox
    # pkgs.tetex
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "less -FirSwX";
  };

  # home.file.".inputrc".source = ./inputrc;

   # xdg.configFile."i3/config".text = builtins.readFile ./i3;
   # xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;

   # tree-sitter parsers
   xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
   xdg.configFile."nvim/queries/proto/folds.scm".source =
     "${sources.tree-sitter-proto}/queries/folds.scm";
   xdg.configFile."nvim/queries/proto/highlights.scm".source =
     "${sources.tree-sitter-proto}/queries/highlights.scm";
   xdg.configFile."nvim/queries/proto/textobjects.scm".source =
     ./textobjects.scm;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = true;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;

    shellAliases = {
      cat = "bat";
      ls = "exa";
      grep = "rg";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";
    };
  };

  programs.direnv= {
    enable = true;
    config = {
      whitelist = {
      #   prefix= [
      #     "$HOME/code/go/src/github.com/hashicorp"
      #     "$HOME/code/go/src/github.com/mitchellh"
      #   ];

        exact = ["$HOME/.envrc"];
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]);

    shellAliases = {
      cat = "bat";
      ls = "exa";
      grep = "rg";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";

      # Two decades of using a Mac has made this such a strong memory
      # that I'm just going to keep it consistent.
      pbcopy = "xclip";
      pbpaste = "xclip -o";
    };

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
    };
  };


  programs.git = {
    enable = true;
    userName = "shayne";
    userEmail = "79330+shayne@users.noreply.github.com";
    signing = {
      key = "69DA13E86BF403B0";
      signByDefault = true;
    };
    aliases = {
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "shayne";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  programs.go = {
    enable = true;
    goPath = "code/go";
    # goPrivate = [ "github.com/mitchellh" "github.com/hashicorp" "rfc822.mx" ];
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"

      set -g @dracula-show-battery false
      set -g @dracula-show-network false
      set -g @dracula-show-weather false

      bind -n C-k send-keys "clear"\; send-keys "Enter"

      run-shell ${sources.tmux-pain-control}/pain_control.tmux
      run-shell ${sources.tmux-dracula}/dracula.tmux
    '';
  };

  # programs.alacritty = {
  #   enable = true;

  #   settings = {
  #     env.TERM = "xterm-256color";

  #     key_bindings = [
  #       { key = "K"; mods = "Command"; chars = "ClearHistory"; }
  #       { key = "V"; mods = "Command"; action = "Paste"; }
  #       { key = "C"; mods = "Command"; action = "Copy"; }
  #       { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
  #       { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
  #       { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
  #     ];
  #   };
  # };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  # programs.i3status = {
  #   enable = true;

  #   general = {
  #     colors = true;
  #     color_good = "#8C9440";
  #     color_bad = "#A54242";
  #     color_degraded = "#DE935F";
  #   };

  #   modules = {
  #     ipv6.enable = false;
  #     "wireless _first_".enable = false;
  #     "battery all".enable = false;
  #   };
  # };

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs; [
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-misc
      customVim.vim-tla
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-nord
      customVim.nvim-lspconfig
      customVim.nvim-treesitter
      customVim.nvim-treesitter-playground
      customVim.nvim-treesitter-textobjects

      vimPlugins.ctrlp
      vimPlugins.vim-airline
      vimPlugins.vim-airline-themes
      vimPlugins.vim-eunuch
      vimPlugins.vim-gitgutter

      vimPlugins.vim-markdown
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  # programs.vscode = {
  #   enable = true;
  #   package = pkgs.vscodium;
  #   extensions = with pkgs.vscode-extensions; [
  #     vscodevim.vim
  #     golang.go
  #     bbenoist.nix
  #     arrterian.nix-env-selector
  #   ];
  # };

  services.gpg-agent = {
    enable = true;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  # xresources.extraConfig = builtins.readFile ./Xresources;

  # # Make cursor not tiny on HiDPI screens
  # xsession.pointerCursor = {
  #   name = "Vanilla-DMZ";
  #   package = pkgs.vanilla-dmz;
  #   size = 16;
  # };
}
