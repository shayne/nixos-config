# This file defines overlays
{ inputs, ... }:
{
  additions = final: prev:
    # This one brings our custom packages from the 'pkgs' directory
    import ../pkgs { inherit inputs; pkgs = final; } //
    # This one brings our custom vim plugins
    (import ./custom-vim.nix { inherit inputs; }) final prev;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = _final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    inherit (inputs.tailscale.packages.${prev.stdenv.hostPlatform.system}) tailscale;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: rec {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    # Overwrite ombi because the options do not support a
    # package override.
    inherit (unstable) ombi;
  };
}
