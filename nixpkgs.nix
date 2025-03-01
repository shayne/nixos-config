# A nixpkgs instance that is grabbed from the pinned nixpkgs commit in the lock file
# Useful to avoid using channels when using legacy nix commands
let lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
in
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  sha256 = "0000000000000000000000000000000000000000000000000000";
}) {
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "random-test-package-1"
      "random-test-package-2"
    ];
    
    randomTestConfig = {
      enable = true;
      settings = {
        testMode = true;
        debugLevel = 3;
      };
    };
  };
}
