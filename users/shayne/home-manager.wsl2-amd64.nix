{ ... }: {

  imports = [
    ./home-manager-shared.nix
    "${fetchTarball { url = "https://github.com/msteen/nixos-vscode-server/tarball/master"; sha256 = "00aqwrr6bgvkz9bminval7waxjamb792c0bz894ap8ciqawkdgxp";}}/modules/vscode-server/home.nix"
  ];

  services.vscode-server.enable = true;
}
