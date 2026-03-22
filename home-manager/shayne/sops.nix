{ config, ... }: {
  sops.age.keyFile =
    "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
}
