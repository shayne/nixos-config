{ config, lib, pkgs, ... }:
let
  # tmux is a second place where macOS launchd/audit sessions matter. Panes are
  # forked by the long-lived tmux server, not by whichever SSH client attaches to
  # it later. If that server was originally created from a normal macOS SSH
  # session, it can keep launchd's "Background" session even after OpenSSH itself
  # has been fixed to re-enter the desktop "Aqua" session.
  #
  # That means `security show-keychain-info` can work in a fresh SSH shell while
  # failing in a new tmux pane attached to an older server. Using default-command
  # makes each new pane shell perform the same Aqua handoff before starting the
  # user's login shell, so keychain-dependent tools behave consistently.
  #
  # This affects newly-created panes/windows. Existing pane shells keep whatever
  # session context they already had; restart those shells if they need keychain
  # access.
  tmuxAquaShell = pkgs.writeShellScript "tmux-aqua-shell" ''
    set -eu

    uid=$(/usr/bin/id -u)
    user=$(/usr/bin/id -un)
    current_manager=$(/bin/launchctl managername 2>/dev/null || true)
    shell=$(/usr/bin/dscl . -read "/Users/$user" UserShell 2>/dev/null | /usr/bin/awk '{print $2; exit}')

    if [ -z "$shell" ] || [ ! -x "$shell" ]; then
      shell=''${SHELL:-/bin/zsh}
    fi

    if [ "$current_manager" = "Aqua" ]; then
      exec "$shell" -l
    fi

    if ! /bin/launchctl print "gui/$uid" >/dev/null 2>&1; then
      echo "tmux-aqua-shell: no gui/$uid session; log in through the desktop session first" >&2
      exit 69
    fi

    exec /usr/bin/sudo -n /bin/launchctl asuser "$uid" \
      /usr/bin/sudo -n -u "$user" /usr/bin/env \
        HOME="$HOME" USER="$user" LOGNAME="$user" SHELL="$shell" TERM="''${TERM-}" \
        SSH_AUTH_SOCK="''${SSH_AUTH_SOCK-}" SSH_CLIENT="''${SSH_CLIENT-}" \
        SSH_CONNECTION="''${SSH_CONNECTION-}" SSH_TTY="''${SSH_TTY-}" \
        "$shell" -l
  '';
in
{
  sops.secrets = {
    beszel_agent_m5studio_key = { };
    beszel_agent_m5studio_token = { };
  };

  sops.templates."beszel-agent-m5studio.env".content = ''
    KEY="${config.sops.placeholder.beszel_agent_m5studio_key}"
    LISTEN=45876
    TOKEN="${config.sops.placeholder.beszel_agent_m5studio_token}"
    HUB_URL="https://beszel.shayne.ts.net"
  '';

  home.file.".config/beszel/beszel-agent.env" = {
    source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."beszel-agent-m5studio.env".path;
    force = true;
  };

  programs.tmux.extraConfig = ''
    set -g default-command ${tmuxAquaShell}
  '';

  launchd.agents.beszel-agent = {
    enable = true;
    config = {
      ProgramArguments = [ "/opt/homebrew/opt/beszel-agent/bin/beszel-agent-launcher" ];
      EnvironmentVariables.HOME = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/.cache/beszel/beszel-agent.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/beszel/beszel-agent.log";
    };
  };

  home.activation.beszelDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.cache/beszel"
    # Migrate the previous Homebrew service out of either launchd domain.
    # An agent left in user/<uid> can conflict with a new gui/<uid> agent.
    for domain in "user/$(id -u)" "gui/$(id -u)"; do
      run /bin/launchctl bootout "$domain/homebrew.mxcl.beszel-agent" 2>/dev/null || true
    done
    run rm -f "$HOME/Library/LaunchAgents/homebrew.mxcl.beszel-agent.plist"
  '';

  # Homebrew activation runs under sudo before SOPS has rendered the env file.
  # Use Home Manager's gui/<uid> agent and restart it after secrets are ready.
  home.activation.beszelService = lib.hm.dag.entryAfter [ "sops-nix" "setupLaunchAgents" "linkGeneration" ] ''
    if [[ ! -v DRY_RUN ]]; then
      rendered_env=${lib.escapeShellArg config.sops.templates."beszel-agent-m5studio.env".path}
      for _ in {1..50}; do
        if [[ -s "$rendered_env" ]]; then
          break
        fi
        sleep 0.1
      done

      if [[ ! -s "$rendered_env" ]]; then
        echo "Beszel env was not rendered at $rendered_env" >&2
        exit 1
      fi

      /bin/launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.beszel-agent"
    fi
  '';
}
