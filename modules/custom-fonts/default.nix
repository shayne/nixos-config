{ config, lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isDarwin (
  let
    encryptedArchive = ../../secrets/custom-fonts.tar.gz;
    ageKeyFile = config.sops.age.keyFile;
  in
  {
    home.activation.installCustomFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      font_dir="$HOME/Library/Fonts/HomeManager/custom-fonts"
      tmp_dir="$(mktemp -d)"
      unpack_dir="$tmp_dir/unpacked"
      archive="$tmp_dir/custom-fonts.tar.gz"
      trap 'rm -rf "$tmp_dir"' EXIT

      mkdir -p "$font_dir"
      mkdir -p "$unpack_dir"
      SOPS_AGE_KEY_FILE=${lib.escapeShellArg ageKeyFile} \
        ${lib.getExe pkgs.sops} decrypt --input-type binary --output-type binary \
        ${lib.escapeShellArg "${encryptedArchive}"} > "$archive"
      /usr/bin/tar -xzf "$archive" -C "$unpack_dir"
      ${pkgs.rsync}/bin/rsync -a --delete "$unpack_dir"/ "$font_dir"/
    '';
  }
)
