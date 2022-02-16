/* This contains various packages we want to overlay. Note that the
 * other ".nix" files in this directory are automatically loaded.
 */
final: prev: {
  consul-bin = final.callPackage ../pkgs/consul-bin.nix {};
  create-dmg = final.callPackage ../pkgs/create-dmg.nix {};
  nomad-bin = final.callPackage ../pkgs/nomad-bin.nix {};
  terraform-bin = final.callPackage ../pkgs/terraform-bin.nix {};

  caddy = final.callPackage ../pkgs/caddy.nix {};

  # Have to force Go 1.17 because the default is fixed to 1.16
  # for reasons in the nixpkgs repository. We'll undo this when
  # they switch.
  go = final.go_1_17;
}
