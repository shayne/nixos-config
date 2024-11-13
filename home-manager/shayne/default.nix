{ config, lib, pkgs, sources, myModulesPath, ... }:

let
  inherit (pkgs.stdenv) isLinux;
in
{
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

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
  # Packages
  #---------------------------------------------------------------------

  home.packages = with pkgs; [
    age
    aws-vault
    bat
    bind
    fd
    fzf
    gcc
    gh
    git-crypt
    # go
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
    sops
    rlwrap
    tree
    upterm # Terminal sharing
    watch
    zoxide

    # unstable packages
    unstable.devbox
    unstable.gokrazy
  ] ++ (lib.optionals isLinux [
    ramfetch
    traceroute
    whois
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

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = true;

  programs.direnv = {
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

  programs.git = {
    enable = true;
    userName = "shayne";
    userEmail = "79330+shayne@users.noreply.github.com";
    signing = {
      key = "69DA13E86BF403B0";
      signByDefault = true;
    };
    aliases = {
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
      amend = "commit --amend --no-edit";
    };
    diff-so-fancy.enable = true;
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
    package = pkgs.unstable.go_1_23;
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
}
