# A nixpkgs instance that is grabbed from the pinned nixpkgs commit in the lock file
# Useful to avoid using channels when using legacy nix commands
import
  (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  })
{
  config = {
    allowUnfree = true;
    allowBroken = true; # Added for testing

    permittedInsecurePackages = [
      "random-test-package-1"
      "random-test-package-2"
      "test-package-3-unstable"
      "experimental-package-4"
      "legacy-package-5"
    ];

    randomTestConfig = {
      enable = true;
      settings = {
        testMode = "advanced";
        debugLevel = 5;
        features = {
          experimental = true;
          testing = true;
          monitoring = {
            enable = true;
            interval = 300;
            targets = [ "cpu" "memory" "disk" ];
          };
        };
      };
    };

    packageOverrides = _pkgs: {
      testPackages = {
        enable = true;
        version = "2.0.0";
        variants = [ "debug" "release" "profile" ];
      };
    };
  };
}
