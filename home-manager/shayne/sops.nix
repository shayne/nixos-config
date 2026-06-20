{ config, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
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
    } // lib.optionalAttrs isDarwin {
      catch_host = { };
    };

    templates."shell-secrets.sh".content = ''
      export OPENAI_API_KEY='${config.sops.placeholder.openai_api_key}'
      export ANTHROPIC_API_KEY='${config.sops.placeholder.anthropic_api_key}'
    '' + lib.optionalString isDarwin ''
      export CATCH_HOST='${config.sops.placeholder.catch_host}'
    '';

    templates."shell-secrets.fish".content = ''
      set -gx OPENAI_API_KEY '${config.sops.placeholder.openai_api_key}'
      set -gx ANTHROPIC_API_KEY '${config.sops.placeholder.anthropic_api_key}'
    '' + lib.optionalString isDarwin ''
      set -gx CATCH_HOST '${config.sops.placeholder.catch_host}'
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
