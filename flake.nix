{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # I think technically you're not supposed to override the nixpkgs
    # used by neovim but recently I had failures if I didn't pin to my
    # own. We can always try to remove that anytime.
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    mach-nix.url = "github:DavHau/mach-nix";
    nixos-vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    lib = nixpkgs.lib;

    overlays = [
      inputs.neovim-nightly-overlay.overlay

      (final: prev: {
        # Go we always want the latest version
        go = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.go_1_19;

        mach-nix = inputs.mach-nix.packages.${prev.system}.mach-nix;

        openvscode-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.openvscode-server;
      })
    ];

    mkSystem = let
      user = "shayne";
    in import ./lib/mkSystem.nix { inherit lib user inputs overlays; };
  in {
    nixosConfigurations =
      mkSystem { name = "devvm"; system = "x86_64-linux"; } //
      mkSystem { name = "m1nix"; system = "aarch64-linux"; } //
      mkSystem { name = "pinix"; system = "aarch64-linux"; } //
      mkSystem { name = "wsl";   system = "x86_64-linux"; };
  };
}
