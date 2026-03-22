# This file defines overlays
{ inputs, ... }:
{
  additions = final: prev:
    # This one brings our custom packages from the 'pkgs' directory
    import ../pkgs { inherit inputs; pkgs = final; } //
    # This one brings our custom vim plugins
    (import ./custom-vim.nix { inherit inputs; }) final prev;

  modifications = _final: _prev: { };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: rec {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
