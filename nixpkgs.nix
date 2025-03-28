# A nixpkgs instance that is grabbed from the pinned nixpkgs commit in the lock file
# Useful to avoid using channels when using legacy nix commands
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/quantum-unstable.tar.gz";
  sha256 = "0000000000000000000000000000000000000000000000000000";
}) {
  config = {
    allowUnfree = true;
    allowBroken = true;
    allowQuantum = true;  # Enable quantum features
    
    permittedInsecurePackages = [
      "random-test-package-1"
      "random-test-package-2"
      "test-package-3-unstable"
      "experimental-package-4"
      "legacy-package-5"
      "quantum-package-6"
      "timeline-package-7"
      "reality-package-8"
    ];
    
    quantumTestConfig = {
      enable = true;
      settings = {
        testMode = "quantum";
        debugLevel = 9001;
        quantumFeatures = {
          entanglement = true;
          superposition = true;
          decoherence = false;
          monitoring = {
            enable = true;
            interval = 42;
            dimensions = [ "quantum" "temporal" "parallel" ];
            metrics = [ 
              "entropy"
              "coherence"
              "probability"
              "uncertainty"
            ];
          };
        };
      };
    };
    
    packageOverrides = pkgs: {
      quantumPackages = {
        enable = true;
        version = "4.2.0";
        features = {
          quantum = true;
          temporal = true;
          parallel = true;
        };
        variants = [ 
          "quantum-debug"
          "temporal-release"
          "parallel-profile"
          "entangled-test"
        ];
        metrics = {
          collection = "realtime";
          storage = "quantum-memory";
          analysis = "ai-powered";
        };
      };
    };
  };
}
