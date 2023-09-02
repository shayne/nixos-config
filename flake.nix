{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

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
    mach-nix.url = "github:DavHau/mach-nix";
    vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      lib = nixpkgs.lib;

      overlays = [
        inputs.neovim-nightly-overlay.overlay

        (final: prev: {
          # need to override the nodejs version to get the unstable
          # code-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.code-server;
          # fish = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.fish;
          go = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.go_1_21;
          gokrazy = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gokrazy;
          mach-nix = inputs.mach-nix.packages.${prev.system}.mach-nix;
          # openvscode-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.openvscode-server;
          starship = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.starship;
          tailscale = inputs.tailscale.packages.${prev.system}.tailscale;
          wslu = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.wslu;
        })
      ];

      user = "shayne";
      mkSystem = import ./lib/mkSystem.nix { inherit lib user inputs overlays; };
      mkDarwin = import ./lib/mkDarwin.nix { inherit lib user inputs overlays; };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          formatter = pkgs.nixpkgs-fmt;
        }) // {

      nixosConfigurations =
        mkSystem { name = "devvm"; system = "x86_64-linux"; } //
        mkSystem { name = "pinix"; system = "aarch64-linux"; } //
        mkSystem { name = "lima"; system = "aarch64-linux"; } //
        mkSystem { name = "wsl"; system = "x86_64-linux"; } //
        mkSystem { name = "m2vm"; system = "aarch64-linux"; } //
        mkSystem {
          name = "m1nix";
          system = "aarch64-linux";
          overlays = [
            inputs.nixos-apple-silicon.overlays.apple-silicon-overlay
          ];
        };
      darwinConfigurations =
        mkDarwin { name = "m2air"; system = "aarch64-darwin"; };
    };
}
