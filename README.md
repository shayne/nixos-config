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

This is an updated random section with even more test content:

- Updated random point 1 with extra info
- Brand new random point with details
- Experimental feature note
- Testing configuration example

### Random Subsection

Some more random text here just to make the diff more interesting.
Feel free to ignore this section as it's just for testing.

### Another Test Subsection

Adding another subsection with more random content:

1. Numbered list item one
2. Another numbered item
3. Yet another item with some `code` formatting

## Testing Features

Just adding another top-level section to test more formatting:

```nix
{
  test.feature = {
    enable = true;
    randomValue = 42;
  };
}
```
