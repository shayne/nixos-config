{ config, inputs, outputs, pkgs, user, ... }:
{
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      inputs.neovim-nightly-overlay.overlay
      inputs.nixos-apple-silicon.overlays.apple-silicon-overlay

      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # TODO: don't do this
      (import ../users/shayne/vim.nix)

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  users.users.${user} = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/${user}";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$UENIoKcP$ku0OwcjMsQaHLhK7FpNGkcBAIMfdqhd74U6ELR3SSIUZidty4hQ4zWZF1y8L82yxaiw4T4pV4T7txN.xa/a6A0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxq71dQw4zBQAe3mtfiNwuCwP0Lu8x9PdRVxy2+T8Pw shayne"
    ];
  };
}
