#!/usr/bin/env bash
set -euo pipefail

rm -rf "machines/m1-support/!(firmware)"

curl -sL https://github.com/tpwrules/nixos-m1/archive/main.tar.gz | \
  tar xz -C machines/ nixos-m1-main/nix/m1-support/ --strip-components=2

git status
