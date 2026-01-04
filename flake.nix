{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    homebrew-bundle = { url = "github:homebrew/homebrew-bundle"; flake = false; };

    # Other packages
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    tailscale.url = "https://flakehub.com/f/tailscale/tailscale/*.tar.gz";
    # 2024-01-01: add to fix "Module is unknown" issue
    tailscale.inputs.nixpkgs.follows = "nixpkgs-unstable";
    vscode-server.url = "github:Ten0/nixos-vscode-server";
    hyprland-contrib = {
      url = "github:shayne/hyprwm-contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flakes
    nvim-conform.url = "github:stevearc/conform.nvim/v5.2.1";
    nvim-conform.flake = false;
    nvim-treesitter.url = "github:nvim-treesitter/nvim-treesitter/v0.9.1";
    nvim-treesitter.flake = false;
    vim-copilot.url = "github:github/copilot.vim/v1.41.0";
    vim-copilot.flake = false;
  };

  outputs = { nixpkgs, ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;
      user = "shayne";
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.11";
      libx = import ./lib { inherit inputs outputs stateVersion user; };
      inherit (nixpkgs) lib;

      systems = libx.loadSystems;
      nixosConfigs = systems.nixosConfigurations or { };
    in
    systems // {
      # nix fmt
      formatter = libx.forAllSystems (system:
        nix-formatter-pack.lib.mkFormatter {
          inherit nixpkgs system;
          config = {
            tools = {
              alejandra.enable = false;
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;
            };
          };
        }
      );

      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = libx.forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; inherit inputs; }
      );

    }
    // lib.optionalAttrs (nixosConfigs != { }) {
      colmena = {
        meta = {
          nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
          nodeNixpkgs = builtins.mapAttrs (_name: value: value.pkgs) nixosConfigs;
          nodeSpecialArgs = builtins.mapAttrs (_name: value: value._module.specialArgs) nixosConfigs;
        };
      } // builtins.mapAttrs (_name: value: { imports = value._module.args.modules; }) nixosConfigs;
    };
}
