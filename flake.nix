{
  description = "NixOS systems and tools by shayne";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
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
        fish = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.fish;
        mach-nix = inputs.mach-nix.packages.${prev.system}.mach-nix;
        openvscode-server = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.openvscode-server;
        starship = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.starship;
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
      mkSystem { name = "wsl";   system = "x86_64-linux"; } //
      mkSystem { name = "m2vm";  system = "aarch64-linux";
        overlays = [(final: prev: {
          # Example of bringing in an unstable package:
          # open-vm-tools = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.open-vm-tools;

          # We need Mesa on aarch64 to be built with "svga". The default Mesa
          # build does not include this: https://github.com/Mesa3D/mesa/blob/49efa73ba11c4cacaed0052b984e1fb884cf7600/meson.build#L192
          mesa = prev.callPackage "${inputs.nixpkgs-unstable}/pkgs/development/libraries/mesa" {
              llvmPackages = final.llvmPackages_latest;
              inherit (final.darwin.apple_sdk.frameworks) OpenGL;
              inherit (final.darwin.apple_sdk.libs) Xplugin;
              galliumDrivers = [
                # From meson.build
                "v3d" "vc4" "freedreno" "etnaviv" "nouveau"
                "tegra" "virgl" "lima" "panfrost" "swrast"
                # We add this so we get the vmwgfx module
                "svga"
              ];
          };
        })];
      };
  };
}
