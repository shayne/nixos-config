{ config, lib, pkgs, currentSystemName, inputs, ... }:

let sources =
    import ../../nix/sources.nix;

    isLinux = pkgs.stdenv.isLinux;

    shellAliases = {
      ga = "git add";
      gam = "git amend";
      gbc = "git branch --merged | grep -v '\*' | awk '{ print $1; }' | xargs -pr git branch -d";
      gc = "git commit -v";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gs = "git status";
      gt = "git tag";

      godlv = "dlv exec --api-version 2 --listen=127.0.0.1:2345 --headless";
    };
in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  imports = [
    ../../secret/modules/ssh.nix
  ];

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = with pkgs; [
    aws-vault
    bat
    bind
    fd
    fzf
    gcc
    gh
    git-crypt
    go
    gopls
    htop
    httpie
    hub
    jq
    nix-diff
    ookla-speedtest
    python3
    ripgrep
    tree
    watch
    whois
    zoxide

    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isLinux [
    traceroute
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
    AWS_VAULT_BACKEND = "pass";
  };

   # tree-sitter parsers
   xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
   xdg.configFile."nvim/queries/proto/folds.scm".source =
     "${sources.tree-sitter-proto}/queries/folds.scm";
   xdg.configFile."nvim/queries/proto/highlights.scm".source =
     "${sources.tree-sitter-proto}/queries/highlights.scm";
   xdg.configFile."nvim/queries/proto/textobjects.scm".source =
     ./textobjects.scm;

  # Rectangle.app. This has to be imported manually using the app.
  xdg.configFile."rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = true;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;

    inherit shellAliases;
  };

  programs.direnv= {
    enable = true;
    nix-direnv = {
        enable = true;
    };
    config = {
      whitelist = {
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

    inherit shellAliases;

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
      "zoxide.fish"
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      gcloud = {
        disabled = true;
      };
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
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
      amend = "commit --amend --no-edit";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      fetch.prune = true;
      github.user = "shayne";
      init.defaultBranch = "main";
      push.default = "tracking";
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
    shortcut = "a";
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

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs; [
      customVim.vim-copilot
      customVim.vim-cue
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-glsl
      customVim.vim-misc
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.vim-zig
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-nord
      customVim.nvim-comment
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
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources; };
  };

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_KEY = "6BF403B0";
    };
  };

  services.gpg-agent = {
    enable = isLinux;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  # syncthing on everything except pinix and darwin
  services.syncthing.enable = if isLinux then if currentSystemName == "pinix" then false else true else false;
}
