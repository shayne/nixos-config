{
  description = "NixOS systems and tools by shayne";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";

      # We want home-manager to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other packages
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    mkVM = import ./lib/mkvm.nix;

    overlays = [
      inputs.neovim-nightly-overlay.overlay

      (final: prev: {
          # ...
      })
    ];
  in {
    nixosConfigurations.vm-unraid = mkVM "vm-unraid" rec {
      inherit nixpkgs home-manager overlays;
      system = "x86_64-linux";
      user   = "shayne";
    };

    nixosConfigurations.wsl2-amd64 = mkVM "wsl2-amd64" rec {
      inherit nixpkgs home-manager overlays;
      system = "x86_64-linux";
      user   = "shayne";
    };
  };
}
