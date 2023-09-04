{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Other packages
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    tailscale.url = "github:tailscale/tailscale";
    vscode-server.url = "github:msteen/nixos-vscode-server";
  };

  outputs = { nixpkgs, ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;
      user = "shayne";
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.05";
      libx = import ./lib { inherit inputs outputs stateVersion; };
      inherit (nixpkgs) lib;

      mkSystem = import ./lib/mkSystem.nix { inherit user inputs outputs stateVersion; };
      mkDarwin = import ./lib/mkDarwin.nix { inherit user inputs outputs stateVersion; };
    in
    {

      nixosConfigurations =
        mkSystem { name = "devvm"; } //
        mkSystem { name = "wsl"; } //
        mkSystem { name = "pinix"; system = "aarch64-linux"; } //
        mkSystem { name = "lima"; system = "aarch64-linux"; } //
        mkSystem { name = "m2vm"; system = "aarch64-linux"; } //
        mkSystem { name = "m1nix"; system = "aarch64-linux"; };
      darwinConfigurations =
        mkDarwin { name = "m2air"; system = "aarch64-darwin"; };

      # Devshell for bootstrapping; acessible via 'nix develop' or 'nix-shell' (legacy)
      devShells = libx.forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

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
        in import ./pkgs { inherit pkgs; }
      );
    };
}
