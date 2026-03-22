{ config, lib, ... }: {
  sops = {
    age.keyFile =
      "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/shayne.yaml;
    defaultSopsFormat = "yaml";

    secrets.openai_api_key = { };
    secrets.anthropic_api_key = { };

    templates."shell-secrets.sh".content = ''
      export OPENAI_API_KEY='${config.sops.placeholder.openai_api_key}'
      export ANTHROPIC_API_KEY='${config.sops.placeholder.anthropic_api_key}'
    '';

    templates."shell-secrets.fish".content = ''
      set -gx OPENAI_API_KEY '${config.sops.placeholder.openai_api_key}'
      set -gx ANTHROPIC_API_KEY '${config.sops.placeholder.anthropic_api_key}'
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
