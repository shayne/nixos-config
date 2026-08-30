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

  piMcpAdapterVersion = "2.28.0";
  piSubagentsVersion = "0.57.0";
  piLensVersion = "4.1.2";
  piLensTypescriptVersion = "7.0.2";
  piFooterVersion = "0.5.1";
  piSubCoreVersion = "1.5.0";
  piCcHeaderVersion = "1.1.1";
  piPrettyVersion = "0.6.24";
  rpivBtwVersion = "2.7.1";
  rpivTodoVersion = "2.7.1";

  piMcpAdapterSource = "npm:pi-mcp-adapter@${piMcpAdapterVersion}";
  piSubagentsSource = "npm:pi-subagents@${piSubagentsVersion}";
  piLensSource = "npm:pi-lens@${piLensVersion}";
  piLensTypescriptSource = "npm:typescript@${piLensTypescriptVersion}";
  piFooterSource = "npm:pi-footer@${piFooterVersion}";
  piSubCoreSource = "npm:@marckrenn/pi-sub-core@${piSubCoreVersion}";
  piCcHeaderSource = "npm:pi-cc-header@${piCcHeaderVersion}";
  piPrettySource = "npm:@heyhuynhgiabuu/pi-pretty@${piPrettyVersion}";
  rpivBtwSource = "npm:@juicesharp/rpiv-btw@${rpivBtwVersion}";
  rpivTodoSource = "npm:@juicesharp/rpiv-todo@${rpivTodoVersion}";

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
    editorPaddingX = 2;

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

    # Keep the Home Manager-owned settings file read-only. Header commands can
    # still change the current session, but declarative settings remain intact.
    ccHeader.readOnlyConfig = true;

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
      piCcHeaderSource
      piPrettySource
      rpivBtwSource
      rpivTodoSource
      "${inputs.superpowers}"
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
      hiddenKeys = [
        "mcp"
        "mcp-auth"
        "pi-lens-lsp"
        "pi-quota:usage"
      ];
      knownKeys = [
        "mcp"
        "mcp-auth"
        "pi-lens-lsp"
        "pi-quota:usage"
      ];
    };
    lines = [
      [
        (footerWidget "agent-icon" "custom-text" {
          raw = true;
          fg = "pi:text";
          text = " ";
        })
        (footerWidget "model-provider" "model-provider" {
          raw = true;
          fg = "pi:warning";
        })
        (footerWidget "thinking" "thinking-level" {
          icon = " · ";
          fg = "pi:thinkingHigh";
          hideWhenEmpty = true;
        })
        (footerWidget "cwd" "cwd-basename" {
          icon = " · ";
          fg = "pi:success";
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

  piLensConfig.widget.visible = false;

  piPrettyConfig = {
    icons = "nerd";
    enableTools = [ "ls" ];
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

    activation.piLensDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${config.home.homeDirectory}/.pi-lens"
      chmod 700 "${config.home.homeDirectory}/.pi-lens"
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
      ".pi/agent/pi-pretty.json".text = builtins.toJSON piPrettyConfig;
      ".pi/agent/pi-sub-core-settings.json".text = builtins.toJSON piSubCoreConfig;
      ".pi/agent/extensions/subagent/config.json".text = builtins.toJSON piSubagentsConfig;
      ".pi-lens/config.json".text = builtins.toJSON piLensConfig;
      ".pi/agent/extensions/prompt-template-display/index.ts".source =
        ./extensions/prompt-template-display/index.ts;
      ".pi/agent/extensions/prompt-template-display/types.d.ts".source =
        ./extensions/prompt-template-display/types.d.ts;
      ".pi/agent/extensions/quota-status/index.ts".source =
        ./extensions/quota-status/index.ts;
    };
  };
}
