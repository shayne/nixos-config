{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";

    nix-formatter-pack.url = "github:Gerschtli/nix-formatter-pack";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";

      # We want to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale = {
      url = "github:tailscale/tailscale";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # I think technically you're not supposed to override the nixpkgs
    # used by neovim but recently I had failures if I didn't pin to my
    # own. We can always try to remove that anytime.
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      # Fails when following nixpkgs, maybe unstable would be
      # fine but I don't think it matters.
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
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

      mkSystem = import ./lib/mkSystem.nix { inherit user inputs outputs; };
      mkDarwin = import ./lib/mkDarwin.nix { inherit user inputs outputs; };
    in
    {
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

      nixosConfigurations =
        mkSystem { name = "devvm"; system = "x86_64-linux"; } //
        mkSystem { name = "pinix"; system = "aarch64-linux"; } //
        mkSystem { name = "lima"; system = "aarch64-linux"; } //
        mkSystem { name = "wsl"; system = "x86_64-linux"; } //
        mkSystem { name = "m2vm"; system = "aarch64-linux"; } //
        mkSystem { name = "m1nix"; system = "aarch64-linux"; };
      darwinConfigurations =
        mkDarwin { name = "m2air"; system = "aarch64-darwin"; };

      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = libx.forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );
    };
}
