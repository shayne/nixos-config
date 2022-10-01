{
  description = "NixOS systems and tools by shayne";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/release-22.05";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";

      # We want home-manager to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    # mach-nix
    mach-nix.url = "github:DavHau/mach-nix";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    lib = nixpkgs.lib;

    overlays = [
      inputs.neovim-nightly-overlay.overlay

      (final: prev: {
        # Go we always want the latest version
        go = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.go_1_19;
        mach-nix = inputs.mach-nix.packages.${prev.system}.mach-nix;
      })
    ];

    mkSystem = let
      user = "shayne";
    in import ./lib/mkSystem.nix { inherit lib user inputs overlays; };
  in {
    nixosConfigurations =
      mkSystem { name = "devvm";   system = "x86_64-linux"; } //
      mkSystem { name = "m1nix"; system = "aarch64-linux"; } //
      mkSystem { name = "pinix";   system = "aarch64-linux"; } //

      mkSystem {
        name = "wsl";
        system = "x86_64-linux";
        modules = [ inputs.nixos-wsl.nixosModules.wsl ];
      };
  };
}
