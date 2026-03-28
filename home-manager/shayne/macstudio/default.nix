{ config, lib, ... }:
{
  sops.secrets = {
    beszel_agent_macstudio_key = { };
    beszel_agent_macstudio_token = { };
  };

  sops.templates."beszel-agent-macstudio.env".content = ''
    KEY="${config.sops.placeholder.beszel_agent_macstudio_key}"
    LISTEN=45876
    TOKEN="${config.sops.placeholder.beszel_agent_macstudio_token}"
    HUB_URL="https://beszel.shayne.ts.net"
  '';

  home.file.".config/beszel/beszel-agent.env" = {
    source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."beszel-agent-macstudio.env".path;
    force = true;
  };

  home.activation.beszelDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/beszel"
  '';

  # nix-darwin runs Homebrew before Home Manager on Darwin, so restart the
  # brew-managed agent only after sops-nix has rendered the env file.
  home.activation.beszelService = lib.hm.dag.entryAfter [ "sops-nix" "linkGeneration" ] ''
    if ! /opt/homebrew/bin/brew list --formula beszel-agent >/dev/null 2>&1; then
      exit 0
    fi

    rendered_env=${lib.escapeShellArg config.sops.templates."beszel-agent-macstudio.env".path}
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

    /opt/homebrew/bin/brew services restart beszel-agent >/dev/null 2>&1 \
      || /opt/homebrew/bin/brew services start beszel-agent >/dev/null
  '';
}
