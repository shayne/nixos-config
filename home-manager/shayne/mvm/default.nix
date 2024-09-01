{ pkgs, ... }:
{
  services.gpg-agent.pinentryPackage = pkgs.pinentry-tty;

  home.packages = with pkgs; [
    pkgs.unstable.distrobox
  ];
}
