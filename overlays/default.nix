# This file defines overlays
{ inputs, ... }:
{
  additions = final: prev:
    # This one brings our custom packages from the 'pkgs' directory
    import ../pkgs { pkgs = final; } //
    # This one brings our custom vim plugins
    import ./custom-vim.nix final prev;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = _final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    inherit (inputs.tailscale.packages.${prev.system}) tailscale;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
