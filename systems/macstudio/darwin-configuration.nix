{ config, pkgs, ... }:
let
  primaryUser = config.system.primaryUser;

  # Plain macOS SSH sessions are created in launchd's "Background" session, even
  # when the same user is already logged in through Screen Sharing/VNC. The login
  # keychain can be unlocked in the desktop "Aqua" session while still returning
  # "User interaction is not allowed" from a normal SSH shell.
  #
  # This ForceCommand preserves the normal UX of `ssh example-host.local`, remote SSH
  # commands, and newly-created tmux servers by re-execing the requested shell or
  # SSH_ORIGINAL_COMMAND inside the existing gui/<uid> Aqua session. It requires
  # the host-local passwordless sudo rule below so sshd can enter the Aqua audit
  # session with `launchctl asuser` and then drop back to the primary user.
  #
  # Do not replace this with pam_launchd `launchd_session_type=Aqua`: a test sshd
  # either failed PAM session setup or still landed in Background. Also note that
  # already-running tmux servers keep their old launchd/audit context; restart
  # them after this change if they need keychain access.
  sshAquaSession = pkgs.writeShellScript "ssh-aqua-session" ''
    set -eu

    uid=$(/usr/bin/id -u)
    user=$(/usr/bin/id -un)
    original_command=''${SSH_ORIGINAL_COMMAND-}
    current_manager=$(/bin/launchctl managername 2>/dev/null || true)
    shell=$(/usr/bin/dscl . -read "/Users/$user" UserShell 2>/dev/null | /usr/bin/awk '{print $2; exit}')

    if [ -z "$shell" ] || [ ! -x "$shell" ]; then
      shell=''${SHELL:-/bin/zsh}
    fi

    if [ "$current_manager" = "Aqua" ]; then
      if [ -n "$original_command" ]; then
        exec "$shell" -lc "$original_command"
      fi

      exec "$shell" -l
    fi

    if ! /bin/launchctl print "gui/$uid" >/dev/null 2>&1; then
      echo "ssh-aqua-session: no gui/$uid session; log in via Screen Sharing or auto-login first" >&2
      exit 69
    fi

    if [ -n "$original_command" ]; then
      exec /usr/bin/sudo -n /bin/launchctl asuser "$uid" \
        /usr/bin/sudo -n -u "$user" /usr/bin/env \
          HOME="$HOME" USER="$user" LOGNAME="$user" SHELL="$shell" TERM="''${TERM-}" \
          SSH_AUTH_SOCK="''${SSH_AUTH_SOCK-}" SSH_CLIENT="''${SSH_CLIENT-}" \
          SSH_CONNECTION="''${SSH_CONNECTION-}" SSH_TTY="''${SSH_TTY-}" \
          "$shell" -lc "$original_command"
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
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macstudio";

  system.stateVersion = 5;

  security.sudo.extraConfig = ''
    ${primaryUser} ALL = (ALL) NOPASSWD: ALL
  '';

  services.openssh.extraConfig = ''
    Match User ${primaryUser}
      ForceCommand ${sshAquaSession}
  '';

  homebrew = {
    enable = true;
    taps = [
      "henrygd/beszel"
      "homebrew/cask"
      "steipete/tap"
      "sichengchen/tap"
    ];
    brews = [
      "bitwarden-cli"
      {
        name = "et";
        start_service = true;
      }
      "gh"
      {
        name = "henrygd/beszel/beszel-agent";
        start_service = true;
      }
      "mise"
      "sichengchen/tap/apple-calendar-cli"
      "steipete/tap/gogcli"
      "steipete/tap/peekaboo"
      "signal-cli"
      "uv"
    ];
    casks = [
      "ngrok"
      "orbstack"
    ];
    masApps = {
      "Xcode" = 497799835;
    };
  };
}
