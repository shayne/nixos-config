# NixOS System Configurations

This repository contains my NixOS system configurations. As of 2023-09-09 it is undergoing a major overhaul.

Check back later for more information.

For now take a look at the [systems](./systems/) and [home-manager](./home-manager/) directories. A lot of the magic
happens in [lib/loadSystems.nix](./lib/loadSystems.nix) and [lib/mkSystem.nix](./lib/mkSystem.nix).

## Current systems

- `devvm` - an x86_64 headless VM for development
- `m1nix` - a 13" M1 MacBook Pro running a NixOS desktop natively ([nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon))
- `m2nix` - a 13" M2 MacBook Air running a NixOS desktop natively ([nixos-apple-silicon](https://github.com/tpwrules/nixos-apple-silicon))
- `m2air` - a 13" M2 MacBook Air running [nix-darwin](https://github.com/LnL7/nix-darwin)
- `wsl` - a WSL2 VM running NixOS ([nixos-wsl](https://github.com/nix-community/NixOS-WSL))

## New Random Section

This section has been completely revamped for more testing:

- [DEPRECATED] Updated random point 1 with extra info
- [NEW] Enhanced testing point with metrics
- [EXPERIMENTAL] AI-powered configuration testing
- [BETA] Quantum configuration randomizer
- [TODO] Add more random testing features

### Random Subsection

> **Warning**: This section contains highly experimental features
> that may cause unexpected quantum fluctuations in your configuration.

### Another Test Subsection

Updating the test content with more structured data:

1. `nix-test --random-mode=chaos`
2. `test-quantum --entangle-configs`
3. `experimental-runner --probability=0.42`

## Testing Features

Updated test configuration with new experimental features:

```nix
{
  test.feature = {
    enable = true;
    randomValue = 42;
    experimentalFeatures = {
      quantum = true;
      ai = {
        enable = true;
        model = "gpt-9000";
        temperature = 0.42;
      };
      chaos = {
        enable = true;
        intensity = 9001;
      };
    };
  };
}
```

## Performance Metrics

| Test Type | Success Rate | Quantum Stability |
| --------- | ------------ | ----------------- |
| Random    | 42%          | Uncertain         |
| Chaos     | 13.37%       | Collapsed         |
| AI        | 99.9%        | Superpositioned   |
