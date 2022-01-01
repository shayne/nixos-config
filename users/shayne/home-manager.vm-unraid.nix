{ ... }: {
  imports = [
    ./home-manager-shared.nix
  ];

  services.gpg-agent.pinentryFlavor = "tty";
}
