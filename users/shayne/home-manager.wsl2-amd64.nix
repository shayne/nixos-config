{ ... }: {

  imports = [
    ./home-manager-shared.nix
    "${fetchTarball { url = "https://github.com/msteen/nixos-vscode-server/tarball/master"; sha256 = "0pvnf5cya0lh1aggrj891xbzyh06jg8mixjl4zn6a1cwr23380qv";}}/modules/vscode-server/home.nix"
  ];

  services.vscode-server.enable = true;
}
