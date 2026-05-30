{ lib, inputs, ... }: {
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
  };

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
    warn-dirty = false
  '';

  programs.nix-index-database.comma.enable = true;
}
