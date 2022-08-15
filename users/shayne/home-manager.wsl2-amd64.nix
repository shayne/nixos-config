{ ... }: {

  imports = [
    ./home-manager-shared.nix
  ];

  services.syncthing.enable = true;

}
