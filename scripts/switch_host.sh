#!/usr/bin/env sh
set -eu

repo_root="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
host="${1:-$(hostname -s)}"
flake_ref="${repo_root}#${host}"

if [ -n "${NIX_CONFIG:-}" ]; then
  NIX_CONFIG="${NIX_CONFIG}
extra-experimental-features = nix-command flakes"
else
  NIX_CONFIG="extra-experimental-features = nix-command flakes"
fi
export NIX_CONFIG

cd "$repo_root"

echo "Switching host ${host}..."

case "$(uname)" in
  Darwin)
    nix build ".#darwinConfigurations.${host}.system"
    sudo env NIX_CONFIG="$NIX_CONFIG" ./result/sw/bin/darwin-rebuild switch --flake "$flake_ref"
    ;;
  Linux)
    if ! nix eval ".#nixosConfigurations.${host}.config.system.build.toplevel" >/dev/null 2>&1; then
      echo "No nixosConfigurations.${host} output exists in this flake." >&2
      exit 1
    fi

    if command -v nixos-rebuild >/dev/null 2>&1; then
      rebuild="$(command -v nixos-rebuild)"
    else
      rebuild="$(nix build --no-link --print-out-paths nixpkgs#nixos-rebuild)/bin/nixos-rebuild"
    fi

    sudo env NIX_CONFIG="$NIX_CONFIG" "$rebuild" switch --flake "$flake_ref"
    ;;
  *)
    echo "Unsupported platform: $(uname)" >&2
    exit 1
    ;;
esac
