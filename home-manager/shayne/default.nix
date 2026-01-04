{ lib, pkgs, sources, myModulesPath, ... }:

let
  inherit (pkgs.stdenv) isLinux;
  env = import ./environment.enc.nix;
in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home = {
    stateVersion = "18.09";

    #---------------------------------------------------------------------
    # Packages
    #---------------------------------------------------------------------

    packages = with pkgs; [
      age
      aws-vault
      bat
      bind
      fd
      ffmpeg
      fzf
      gcc
      gh
      git-crypt
      # go
      google-cloud-sdk
      gopls
      htop
      httpie
      hub
      jq
      mosh
      nix-diff
      nodejs # Node is required for Copilot.vim
      nodePackages.prettier
      ookla-speedtest
      python3
      ripgrep
      rlwrap
      silver-searcher
      sops
      tree
      upterm # Terminal sharing
      watch
      zoxide

      # unstable packages
      # ...
    ] ++ (lib.optionals isLinux [
      ramfetch
      traceroute
      whois
    ]);

    #---------------------------------------------------------------------
    # Env vars and dotfiles
    #---------------------------------------------------------------------

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "less -FirSwX";
      MANPAGER = "${pkgs.bat}/bin/bat -l man -p";
      AWS_VAULT_BACKEND = "pass";
    } // env;

    # Prevent the "Last login" message from showing up
    file.".hushlogin".text = "";
  };

  imports = [
    (myModulesPath + "/bash")
    (myModulesPath + "/fish")
    (myModulesPath + "/neovim")
    (myModulesPath + "/ssh")
    (myModulesPath + "/starship")
    (myModulesPath + "/tree-sitter")
  ];

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
  programs = {
    gpg.enable = true;

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      config = {
        whitelist = {
          exact = [ "$HOME/.envrc" ];
        };
      };
    };

    git = {
      enable = true;
      signing = {
        key = "69DA13E86BF403B0";
        signByDefault = true;
      };
      settings = {
        user = {
          name = "shayne";
          email = "79330+shayne@users.noreply.github.com";
        };
        alias = {
          cleanup = "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          root = "rev-parse --show-toplevel";
          amend = "commit --amend --no-edit";
        };
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

    diff-so-fancy = {
      enable = true;
      enableGitIntegration = true;
    };

    go = {
      enable = true;
      package = pkgs.unstable.go_1_24;
    };

    ssh.enableDefaultConfig = false;

    tmux = {
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

    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_KEY = "6BF403B0";
      };
    };
  };

  services.gpg-agent = {
    enable = isLinux;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };
}
