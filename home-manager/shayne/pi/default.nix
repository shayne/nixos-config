{ config, inputs, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  piPackage = inputs.llm-agents.packages.${system}.pi;

  # OpenCode's checked-in configuration is the source of truth for the local
  # provider. Pi translates that provider into its native models.json schema.
  opencodeConfig = builtins.fromJSON (builtins.readFile ../m5mbp/opencode.json);
  localModelParts = lib.splitString "/" opencodeConfig.model;
  localProviderName = builtins.head localModelParts;
  localModelId = lib.last localModelParts;
  localProvider = opencodeConfig.provider.${localProviderName};
  localModel = localProvider.models.${localModelId};

  piMcpAdapterVersion = "2.21.1";
  piSubagentsVersion = "0.44.0";
  piLensVersion = "3.8.74";
  piLensTypescriptVersion = "7.0.2";
  piFooterVersion = "0.5.1";
  piSubCoreVersion = "1.5.0";
  piCcHeaderVersion = "0.9.4";
  rpivBtwVersion = "2.4.0";
  rpivTodoVersion = "2.4.0";

  piMcpAdapterSource = "npm:pi-mcp-adapter@${piMcpAdapterVersion}";
  piSubagentsSource = "npm:pi-subagents@${piSubagentsVersion}";
  piLensSource = "npm:pi-lens@${piLensVersion}";
  piLensTypescriptSource = "npm:typescript@${piLensTypescriptVersion}";
  piFooterSource = "npm:pi-footer@${piFooterVersion}";
  piSubCoreSource = "npm:@marckrenn/pi-sub-core@${piSubCoreVersion}";
  piCcHeaderSource = "npm:pi-cc-header@${piCcHeaderVersion}";
  rpivBtwSource = "npm:@juicesharp/rpiv-btw@${rpivBtwVersion}";
  rpivTodoSource = "npm:@juicesharp/rpiv-todo@${rpivTodoVersion}";

  piCcHeaderUpstream = pkgs.fetchFromGitHub {
    owner = "eriiic7z";
    repo = "pi-cc-header";
    rev = "v${piCcHeaderVersion}";
    hash = "sha256-lBYwrsQh2mywAucvOePVgoWtC7jZJIiOlv8r5t6lwm8=";
  };
  piCcHeaderPatched =
    pkgs.runCommand "pi-cc-header-${piCcHeaderVersion}-patched" { nativeBuildInputs = [ pkgs.patch ]; }
      ''
        cp -R ${piCcHeaderUpstream} "$out"
        chmod -R u+w "$out"
        patch -d "$out" -p1 < ${./patches/pi-cc-header-writable-state.patch}
      '';

  # Pi installs npm-backed packages globally. Keep those mutable resources in
  # Pi's user-owned state rather than pointing npm at the read-only Nix store.
  piNpmPackage = pkgs.writeShellApplication {
    name = "pi-npm";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.pi/agent/npm-global"
      export NPM_CONFIG_AUDIT=false
      export NPM_CONFIG_FUND=false
      export NPM_CONFIG_LOGLEVEL=error

      exec npm --loglevel=error --no-audit --no-fund "$@"
    '';
  };

  # Export only the local-model credential into Pi's process. auth.json and
  # existing sessions remain mutable and unmanaged under ~/.pi/agent.
  piWrapperPackage = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      piPackage
      pkgs.coreutils
    ];
    text = ''
      export PI_TELEMETRY=0

      local_llm_api_key_path=${lib.escapeShellArg config.sops.secrets.local_llm_api_key.path}
      if [ ! -r "$local_llm_api_key_path" ]; then
        echo "pi: local LLM API key is missing or unreadable: $local_llm_api_key_path" >&2
        exit 1
      fi

      LOCAL_LLM_API_KEY="$(cat "$local_llm_api_key_path")"
      export LOCAL_LLM_API_KEY

      pi_resume=(--continue)
      case "''${1:-}" in
        install | remove | uninstall | update | list | config | -h | --help | -v | --version)
          pi_resume=()
          ;;
        *)
          for arg in "$@"; do
            case "$arg" in
              -c | --continue | -r | --resume | --session | --session-id | --fork | --no-session | -p | --print)
                pi_resume=()
                break
                ;;
            esac
          done
          ;;
      esac

      exec ${lib.getExe piPackage} "''${pi_resume[@]}" "$@"
    '';
  };

  piSettings = {
    defaultProvider = localProviderName;
    defaultModel = localModelId;
    defaultThinkingLevel = "medium";
    thinkingBudgets = {
      minimal = 1024;
      low = 4096;
      medium = 10240;
      high = 32768;
      xhigh = 64000;
    };
    hideThinkingBlock = true;
    enabledModels = [ opencodeConfig.model ];

    quietStartup = true;
    clearOnStart = true;
    collapseChangelog = true;
    enableInstallTelemetry = false;
    enableAnalytics = false;
    doubleEscapeAction = "tree";
    treeFilterMode = "default";
    autocompleteMaxVisible = 8;

    compaction = {
      enabled = true;
      reserveTokens = 16384;
      keepRecentTokens = 20000;
    };
    retry = {
      enabled = true;
      maxRetries = 5;
      baseDelayMs = 3000;
      provider = {
        maxRetries = 3;
        maxRetryDelayMs = 120000;
      };
    };
    markdown.codeBlockIndent = " ";

    packages = [
      piMcpAdapterSource
      piSubagentsSource
      piLensSource
      {
        source = piLensTypescriptSource;
        extensions = [ ];
        skills = [ ];
        prompts = [ ];
        themes = [ ];
      }
      piFooterSource
      piSubCoreSource
      {
        source = piCcHeaderSource;
        extensions = [ ];
      }
      rpivBtwSource
      rpivTodoSource
    ];

    extensions = [ ];
    skills = [ "skills" ];
    prompts = [ "prompts/*.md" ];
    enableSkillCommands = true;
    npmCommand = [ "${piNpmPackage}/bin/pi-npm" ];
  };

  piModels = {
    providers.${localProviderName} = {
      baseUrl = localProvider.options.baseURL;
      api = "openai-completions";
      apiKey = "$LOCAL_LLM_API_KEY";
      models = [
        {
          id = localModelId;
          inherit (localModel) name;
          reasoning = localModel.reasoning or false;
          input = [ "text" ];
          contextWindow = localModel.limit.context;
          maxTokens = localModel.limit.output;
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
      ];
    };
  };

  piMcpConfig = {
    settings = {
      directTools = false;
      disableProxyTool = false;
      autoAuth = false;
      sampling = false;
      samplingAutoApprove = false;
    };
    mcpServers = { };
  };

  piKeybindings = {
    "app.exit" = [ "ctrl+d" ];
    "tui.select.cancel" = [ "escape" ];
  };

  footerWidget = id: type: options: {
    inherit id type options;
    enabled = true;
  };
  piFooterConfig = {
    version = 1;
    enabled = true;
    preset = "pi-footer";
    separator = "none";
    separatorFg = "default";
    separatorBg = "default";
    iconMode = "text";
    minimalist = false;
    terminal = {
      widthMode = "full";
      colorLevel = "ansi256";
    };
    extensionStatusRow = {
      hiddenKeys = [ "pi-quota:usage" ];
      knownKeys = [ "pi-quota:usage" ];
    };
    lines = [
      [
        (footerWidget "model-provider" "model-provider" {
          raw = true;
          fg = "pi:warning";
        })
        (footerWidget "thinking" "thinking-level" {
          icon = " · ";
          fg = "pi:thinkingHigh";
          hideWhenEmpty = true;
        })
        (footerWidget "cwd" "cwd" {
          icon = " · ";
          fg = "pi:success";
          cwdDisplayStyle = "full-home";
          segments = 3;
        })
        (footerWidget "quota" "external-status" {
          icon = " · ";
          fg = "pi:error";
          externalStatusKey = "pi-quota:usage";
          hideWhenEmpty = true;
          trimValue = 0;
          preserveTrimStyles = true;
        })
        (footerWidget "context-window" "context-window" {
          icon = " · ";
          fg = "pi:bashMode";
          tokenFormatStyle = "compact";
          contextConditionalColors = true;
          warningFg = "pi:warning";
          dangerFg = "pi:error";
        })
        (footerWidget "context-window-label" "custom-text" {
          raw = true;
          fg = "pi:bashMode";
          text = " window";
        })
        (footerWidget "context-used" "context" {
          icon = " · Context ";
          fg = "pi:bashMode";
          tokenFormatStyle = "compact";
          contextConditionalColors = true;
          warningFg = "pi:warning";
          dangerFg = "pi:error";
        })
        (footerWidget "context-used-label" "custom-text" {
          raw = true;
          fg = "pi:bashMode";
          text = " used";
        })
      ]
    ];
  };

  piSubCoreConfig = {
    version = 3;
    behavior = {
      refreshInterval = 5;
      minRefreshInterval = 5;
      refreshOnTurnStart = true;
      refreshOnToolResult = false;
    };
  };

  piSubagentsConfig = {
    asyncByDefault = false;
    forceTopLevelAsync = false;
    parallel = {
      maxTasks = 4;
      concurrency = 2;
    };
    defaultSessionDir = "~/.pi/agent/sessions/subagent";
    maxSubagentDepth = 1;
    intercomBridge.mode = "off";
  };
in
assert builtins.length localModelParts == 2;
assert localProvider.npm == "@ai-sdk/openai-compatible";
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home = {
    activation.piLegacySettingsBackup = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      settings="${config.home.homeDirectory}/.pi/agent/settings.json"
      backup="${config.home.homeDirectory}/.pi/agent/settings.pre-home-manager.json"
      if [[ -f "$settings" && ! -L "$settings" && ! -e "$backup" ]]; then
        cp "$settings" "$backup"
        chmod 600 "$backup"
        echo "Backed up existing Pi settings to $backup"
      fi
    '';

    activation.piStateDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p \
        "${config.home.homeDirectory}/.pi-lens" \
        "${config.home.homeDirectory}/.pi/agent/state"
      chmod 700 \
        "${config.home.homeDirectory}/.pi-lens" \
        "${config.home.homeDirectory}/.pi/agent/state"
      if [[ ! -e "${config.home.homeDirectory}/.pi/agent/state/pi-cc-header.json" ]]; then
        printf '{}\n' > "${config.home.homeDirectory}/.pi/agent/state/pi-cc-header.json"
      fi
      chmod 600 "${config.home.homeDirectory}/.pi/agent/state/pi-cc-header.json"
    '';

    packages = [
      piNpmPackage
      piWrapperPackage
    ];

    file = {
      ".pi/agent/settings.json" = {
        force = true;
        text = builtins.toJSON piSettings;
      };
      ".pi/agent/models.json".text = builtins.toJSON piModels;
      ".pi/agent/mcp.json".text = builtins.toJSON piMcpConfig;
      ".pi/agent/keybindings.json".text = builtins.toJSON piKeybindings;
      ".pi/agent/extensions/pi-footer.json".text = builtins.toJSON piFooterConfig;
      ".pi/agent/pi-sub-core-settings.json".text = builtins.toJSON piSubCoreConfig;
      ".pi/agent/extensions/subagent/config.json".text = builtins.toJSON piSubagentsConfig;
      ".pi/agent/extensions/pi-cc-header.ts".source =
        "${piCcHeaderPatched}/extensions/pi-cc-header.ts";
      ".pi/agent/extensions/prompt-template-display/index.ts".source =
        ./extensions/prompt-template-display/index.ts;
      ".pi/agent/extensions/prompt-template-display/types.d.ts".source =
        ./extensions/prompt-template-display/types.d.ts;
      ".pi/agent/extensions/quota-status/index.ts".source =
        ./extensions/quota-status/index.ts;
    };
  };
}
