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

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };

    # Other packages
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    # Non-flakes
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
