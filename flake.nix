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
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }@inputs: let
    overlays = [
      inputs.neovim-nightly-overlay.overlay

      (final: prev: {
        # Go we always want the latest version
        go = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.go_1_18;

        # To get Kitty 0.24.x. Delete this once it hits release.
        kitty = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.kitty;
      })
    ];

    mkSystem = import ./lib/mkSystem.nix {
      inherit inputs overlays;
      user = "shayne";
      lib = nixpkgs.lib;
    };
  in {
    nixosConfigurations = 
      mkSystem { name = "devvm";   system = "x86_64-linux"; } //
      mkSystem { name = "macbook"; system = "aarch64-linux"; } //
      mkSystem { name = "pinix";   system = "aarch64-linux"; } //

      mkSystem {
        name = "wsl";
        system = "x86_64-linux";
        modules = [ nixos-wsl.nixosModules.wsl ];
      };
  };
}
