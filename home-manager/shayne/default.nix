{ config, lib, pkgs, sources, myModulesPath, ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
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
      (python3.withPackages (ps: with ps; [
        pyyaml
      ]))
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
      SOPS_AGE_SSH_PRIVATE_KEY_FILE = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };

    # Prevent the "Last login" message from showing up
    file.".hushlogin".text = "";
  };

  imports = [
    ./sops.nix
    (myModulesPath + "/bash")
    (myModulesPath + "/custom-fonts")
    (myModulesPath + "/fish")
    (myModulesPath + "/neovim")
    (myModulesPath + "/ssh")
    (myModulesPath + "/starship")
    (myModulesPath + "/tree-sitter")
  ];

  xdg.enable = true;
  xdg.configFile."git/allowed_signers".text =
    "79330+shayne@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxq71dQw4zBQAe3mtfiNwuCwP0Lu8x9PdRVxy2+T8Pw\n";

  # Home Manager's manpage generation currently forces options docs evaluation
  # and triggers an upstream string-context warning during darwin-rebuild.
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };

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
        format = "ssh";
        key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
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
        gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
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
      package = pkgs.unstable.go_1_26;
    };

    ssh.enableDefaultConfig = false;

    tmux = {
      enable = true;
      terminal = "xterm-256color";
      shortcut = "a";
      secureSocket = false;

      extraConfig = ''
        set -ga terminal-overrides ",*256col*:Tc"
        set -g mouse on

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
    enable = isLinux || isDarwin;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
    pinentry.package = if isDarwin then pkgs.pinentry_mac else null;
  };

  # Home Manager's Darwin gpg-agent launchd job currently uses socket activation
  # with `--supervised`, which exits on this setup. Keep the config file it
  # generates, but use launchd to restart a normal agent in the GUI session
  # whenever the standard socket disappears so SSH and local shells share it.
  launchd.agents.gpg-agent = lib.mkIf isDarwin {
    config = {
      KeepAlive = lib.mkForce {
        PathState."${config.programs.gpg.homedir}/S.gpg-agent" = false;
      };
      ProgramArguments = lib.mkForce [
        (lib.getExe pkgs.bash)
        "-lc"
        ''
          if ! ${lib.getExe' config.programs.gpg.package "gpg-connect-agent"} /bye >/dev/null 2>&1; then
            exec ${lib.getExe' config.programs.gpg.package "gpg-agent"} --daemon
          fi
        ''
      ];
      RunAtLoad = lib.mkForce true;
      Sockets = lib.mkForce null;
    };
  };
}
