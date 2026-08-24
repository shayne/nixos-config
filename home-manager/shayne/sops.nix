{ config, lib, ... }:

{
  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ../../secrets/shayne.yaml;
    defaultSopsFormat = "yaml";
    environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE =
      "${config.home.homeDirectory}/.ssh/id_ed25519";

    secrets = {
      openai_api_key = { };
      anthropic_api_key = { };
      local_llm_api_key = { };
      tailscale_client_id = { };
      tailscale_client_secret = { };
    };

    templates."shell-secrets.sh".content = ''
      export OPENAI_API_KEY='${config.sops.placeholder.openai_api_key}'
      export ANTHROPIC_API_KEY='${config.sops.placeholder.anthropic_api_key}'
      export LOCAL_LLM_API_KEY='${config.sops.placeholder.local_llm_api_key}'
      export TAILSCALE_CLIENT_ID='${config.sops.placeholder.tailscale_client_id}'
      export TAILSCALE_CLIENT_SECRET='${config.sops.placeholder.tailscale_client_secret}'
    '';

    templates."shell-secrets.fish".content = ''
      set -gx OPENAI_API_KEY '${config.sops.placeholder.openai_api_key}'
      set -gx ANTHROPIC_API_KEY '${config.sops.placeholder.anthropic_api_key}'
      set -gx LOCAL_LLM_API_KEY '${config.sops.placeholder.local_llm_api_key}'
      set -gx TAILSCALE_CLIENT_ID '${config.sops.placeholder.tailscale_client_id}'
      set -gx TAILSCALE_CLIENT_SECRET '${config.sops.placeholder.tailscale_client_secret}'
    '';
  };

  programs.bash.initExtra = lib.mkAfter ''
    if [ -f "${config.sops.templates."shell-secrets.sh".path}" ]; then
      . "${config.sops.templates."shell-secrets.sh".path}"
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if test -f ${lib.escapeShellArg config.sops.templates."shell-secrets.fish".path}
      source ${lib.escapeShellArg config.sops.templates."shell-secrets.fish".path}
    end
  '';
}
