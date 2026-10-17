{ config, inputs, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  # Node mode retains the SDK modules that @tintinweb/pi-subagents imports for
  # native background sessions.
  piPackage = (inputs.llm-agents.packages.${system}.pi.override { useBun = false; }).overrideAttrs {
    dontNpmPrune = true;
  };

  # OpenCode's checked-in configuration is the source of truth for the local
  # provider. Pi translates that provider into its native models.json schema.
  opencodeConfig = builtins.fromJSON (builtins.readFile ../m5mbp/opencode.json);
  localModelParts = lib.splitString "/" opencodeConfig.model;
  localProviderName = builtins.head localModelParts;
  localModelId = lib.last localModelParts;
  localProvider = opencodeConfig.provider.${localProviderName};
  localModel = localProvider.models.${localModelId};

  # Exact npm versions and Git revisions stay pinned during package updates.
  # The pi-mcp-adapter pin is the v5.2.0 release commit, which supports Pi 1.0
  # and carries the GHSA-6qxp-vccf-f47h fix.
  piMcpAdapterRevision = "80fcdef8d9f6958751f1e225f88b272440caa542";
  # @tintinweb/pi-subagents 0.20.0 requires Pi 1.1.0 or later.
  piSubagentsVersion = "0.20.0";
  piLensVersion = "4.4.1";
  piLensTypescriptVersion = "7.0.2";
  piFooterVersion = "0.5.1";
  piSubCoreVersion = "1.5.0";
  piCcHeaderVersion = "1.1.1";
  piPrettyVersion = "0.6.31";
  rpivAskUserQuestionVersion = "2.12.0";
  rpivBtwVersion = "2.12.0";
  piTasksVersion = "0.9.1";

  piMcpAdapterSource = "git:github.com/nicobailon/pi-mcp-adapter@${piMcpAdapterRevision}";
  piSubagentsSource = "npm:@tintinweb/pi-subagents@${piSubagentsVersion}";
  piLensSource = "npm:pi-lens@${piLensVersion}";
  piLensTypescriptSource = "npm:typescript@${piLensTypescriptVersion}";
  piFooterSource = "npm:pi-footer@${piFooterVersion}";
  piSubCoreSource = "npm:@marckrenn/pi-sub-core@${piSubCoreVersion}";
  piCcHeaderSource = "npm:pi-cc-header@${piCcHeaderVersion}";
  piPrettySource = "npm:@heyhuynhgiabuu/pi-pretty@${piPrettyVersion}";
  rpivAskUserQuestionSource = "npm:@juicesharp/rpiv-ask-user-question@${rpivAskUserQuestionVersion}";
  rpivBtwSource = "npm:@juicesharp/rpiv-btw@${rpivBtwVersion}";
  piTasksSource = "npm:@tintinweb/pi-tasks@${piTasksVersion}";

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

  # Automatic light/dark mode: Pi picks the theme matching the terminal's
  # reported background (falling back to the terminal's light/dark
  # notification, then COLORFGBG, then dark) and switches live when the
  # terminal appearance changes.
  piThemeLight = "catppuccin-latte";
  piThemeDark = "catppuccin-mocha";
  piTheme = "${piThemeLight}/${piThemeDark}";

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

    theme = piTheme;
    quietStartup = true;
    clearOnStart = true;
    collapseChangelog = true;
    enableInstallTelemetry = false;
    enableAnalytics = false;
    doubleEscapeAction = "tree";
    treeFilterMode = "default";
    autocompleteMaxVisible = 8;
    editorPaddingX = 2;
    # Let the terminal emulator draw the cursor. The hardware-cursor extension
    # strips Pi's inverse-block editor cursor while this key is true, so the
    # emulator's cursor is the only one shown.
    showHardwareCursor = true;

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
    # `color = "b"` selects the blue header logo.
    ccHeader = {
      readOnlyConfig = true;
      color = "b";
      slogan = "May Pi serve you well";
    };

    # Disable native MCP explicitly so pi-mcp-adapter owns MCP behaviour
    # without needing to rewrite this Home Manager-owned settings file.
    extensions = [ "-builtin:mcp" ];

    themes = [ "themes/*.json" ];
    skills = [ "skills" ];
    prompts = [ "prompts/*.md" ];
    enableSkillCommands = true;
    npmCommand = [ "${piNpmPackage}/bin/pi-npm" ];

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
      rpivAskUserQuestionSource
      rpivBtwSource
      piTasksSource
      "${inputs.superpowers}"
    ];
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
      # Keep direct tools opt-in per server. Project-level
      # `.pi/mcp-adapter.json` can override these settings.
      directTools = false;
      disableProxyTool = false;
      # Keep the mcpScript proxy and scripting skill available to agents.
      scriptMode = true;
      scriptSkill = "model";
      autoAuth = false;
      sampling = false;
      samplingAutoApprove = false;
    };
    mcpServers = { };
  };

  piKeybindings = {
    # Unify quit on Ctrl+D across agents; `app.interrupt` stays on Escape and
    # Ctrl+C remains the editor-clear shortcut (non-exit semantics).
    "app.exit" = [ "ctrl+d" ];
    # Drop Ctrl+C from list-cancel so the key is reserved for editor-clear.
    "tui.select.cancel" = [ "escape" ];
  };

  piFooterWidget = id: type: options: {
    inherit id type;
    enabled = true;
    inherit options;
  };

  piFooterColors = {
    agentIcon = "pi:text";
    model = "pi:warning";
    thinking = "pi:warning";
    cwd = "pi:success";
    quota = "pi:error";
    context = "pi:bashMode";
  };

  # pi-footer owns the full footer layout while the local quota-status
  # extension publishes compact provider quota text through
  # `ctx.ui.setStatus("pi-quota:usage", ...)`.
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
    # pi-footer drops the extension status row entirely when every published
    # key is hidden. The MCP and pi-lens statuses are static noise; the
    # pi-quota status duplicates the dedicated footer widget.
    extensionStatusRow = {
      hiddenKeys = [
        "mcp"
        "mcp-auth"
        "pi-quota:usage"
        "pi-lens-lsp"
      ];
      knownKeys = [
        "mcp"
        "mcp-auth"
        "pi-quota:usage"
        "pi-lens-lsp"
      ];
    };
    lines = [
      [
        # White Pi glyph so the footer reads as Pi at a glance.
        (piFooterWidget "agent-icon" "custom-text" {
          raw = true;
          fg = piFooterColors.agentIcon;
          text = "π ";
        })
        (piFooterWidget "model" "model" {
          raw = true;
          fg = piFooterColors.model;
        })
        (piFooterWidget "thinking" "thinking-level" {
          icon = " ";
          fg = piFooterColors.thinking;
          hideWhenEmpty = true;
        })
        (piFooterWidget "cwd" "cwd-basename" {
          icon = " · ";
          fg = piFooterColors.cwd;
        })
        (piFooterWidget "quota" "external-status" {
          icon = " · ";
          fg = piFooterColors.quota;
          externalStatusKey = "pi-quota:usage";
          hideWhenEmpty = true;
          trimValue = 0;
          preserveTrimStyles = true;
        })
        (piFooterWidget "context-window" "context-window" {
          icon = " · ";
          fg = piFooterColors.context;
          tokenFormatStyle = "compact";
          contextConditionalColors = true;
          warningFg = "pi:warning";
          dangerFg = "pi:error";
        })
        (piFooterWidget "context-window-label" "custom-text" {
          raw = true;
          fg = piFooterColors.context;
          text = " window";
        })
        (piFooterWidget "context-used" "context" {
          icon = " · Context ";
          fg = piFooterColors.context;
          tokenFormatStyle = "compact";
          contextConditionalColors = true;
          warningFg = "pi:warning";
          dangerFg = "pi:error";
        })
        (piFooterWidget "context-used-label" "custom-text" {
          raw = true;
          fg = piFooterColors.context;
          text = " used";
        })
      ]
    ];
  };

  piLensConfig.widget.visible = false;

  # pi-pretty reads ~/.pi/agent/pi-pretty.json once at startup. Its Shiki
  # syntax theme is static per session (no light/dark support), so it stays
  # pinned to Mocha; syntax text colours remain legible on light backgrounds
  # while all panel chrome follows the Pi light/dark theme. `ls` is opt-in
  # upstream so it is enabled here. Do not install pi-fff alongside it:
  # both claim the same built-in tool names.
  piPrettyConfig = {
    theme = piThemeDark;
    icons = "nerd";
    enableTools = [ "ls" ];
  };

  # sub-core does not fetch quota data on session start; it first renders
  # cached state, then waits for its refresh timer. Keep that timer short
  # enough that the footer fills in promptly, and refresh again when work
  # starts.
  piSubCoreConfig = {
    version = 3;
    behavior = {
      refreshInterval = 5;
      minRefreshInterval = 5;
      refreshOnTurnStart = true;
      refreshOnToolResult = false;
    };
  };

  # @tintinweb/pi-subagents settings. Background pools are independent of the
  # foreground pool. `worktreeIsolation` stays off: 0.20.0 force-removes
  # worktrees after preservation errors, so isolation requests fail rather
  # than silently losing uncommitted work.
  piSubagentsConfig = {
    backgroundByDefault = true;
    maxConcurrent = 12;
    maxConcurrentForeground = 12;
    maxSubagentDepth = 1;
    defaultMaxTurns = 50;
    graceTurns = 5;
    defaultJoinMode = "async";
    disableDefaultAgents = true;
    fallbackSubagent = "none";
    strictAgentFiles = true;
    rememberAgents = true;
    outputTranscript = true;
    workflowsEnabled = true;
    agentMentions = "off";
    schedulingEnabled = false;
    worktreeIsolation = false;
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

    # Remove Home Manager symlinks left behind by earlier Pi configurations.
    # Only symlinks are removed, so any user-owned file with the same name
    # is untouched.
    activation.piLegacyManagedFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      home="${config.home.homeDirectory}"
      for legacy in \
        "$home/.pi/agent/mcp.json" \
        "$home/.pi/agent/extensions/subagent/config.json"
      do
        if [[ -L "$legacy" ]]; then
          rm -f "$legacy"
        fi
      done
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
      ".pi/agent/mcp-adapter.json".text = builtins.toJSON piMcpConfig;
      ".pi/agent/models.json".text = builtins.toJSON piModels;
      ".pi/agent/keybindings.json".text = builtins.toJSON piKeybindings;
      ".pi/agent/extensions/pi-footer.json".text = builtins.toJSON piFooterConfig;
      ".pi/agent/pi-pretty.json".text = builtins.toJSON piPrettyConfig;
      ".pi/agent/pi-sub-core-settings.json".text = builtins.toJSON piSubCoreConfig;
      ".pi/agent/subagents.json".text = builtins.toJSON piSubagentsConfig;
      ".pi/agent/themes/catppuccin-latte.json".source = ./themes/catppuccin-latte.json;
      ".pi/agent/themes/catppuccin-mocha.json".source = ./themes/catppuccin-mocha.json;
      ".pi/agent/extensions/hardware-cursor/index.ts".source =
        ./extensions/hardware-cursor/index.ts;
      ".pi/agent/extensions/prompt-template-display/index.ts".source =
        ./extensions/prompt-template-display/index.ts;
      ".pi/agent/extensions/prompt-template-display/types.d.ts".source =
        ./extensions/prompt-template-display/types.d.ts;
      ".pi/agent/extensions/quota-status/index.ts".source =
        ./extensions/quota-status/index.ts;
      ".pi-lens/config.json".text = builtins.toJSON piLensConfig;
    };
  };
}
