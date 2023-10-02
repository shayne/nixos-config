{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Neovim breaks on darwin beyond v0.9.1. Must follow nixpkgs for the
    # neovim-flake input for arm64/darwin to build.
    # See: https://github.com/nix-community/neovim-nightly-overlay/issues/176
    neovim-flake.url = "github:neovim/neovim/v0.9.1?dir=contrib";
    neovim-flake.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.neovim-flake.follows = "neovim-flake";

    # Other packages
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    tailscale.url = "https://flakehub.com/f/tailscale/tailscale/*.tar.gz";
    vscode-server.url = "github:msteen/nixos-vscode-server";
  };

  outputs = { nixpkgs, ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;
      user = "shayne";
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "23.05";
      libx = import ./lib { inherit inputs outputs stateVersion user; };
      inherit (nixpkgs) lib;
    in
    libx.loadSystems // {
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
