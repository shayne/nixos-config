{ config, lib, pkgs, ... }:
let
  archivePath = config.sops.secrets.custom-fonts-archive.path;
in
{
  sops.secrets.custom-fonts-archive = {
    sopsFile = ../../secrets/custom-fonts.tar.gz;
    format = "binary";
    path = "%r/custom-fonts.tar.gz";
  };

  home.activation.installCustomFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    font_dir="$HOME/Library/Fonts"
    archive=${lib.escapeShellArg archivePath}
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    mkdir -p "$font_dir"
    ${pkgs.gnutar}/bin/tar -xzf "$archive" -C "$tmp_dir"
    ${pkgs.rsync}/bin/rsync -a --delete "$tmp_dir"/ "$font_dir"/
  '';
}
