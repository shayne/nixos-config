/* This contains various packages we want to overlay. Note that the
 * other ".nix" files in this directory are automatically loaded.
 */
final: _prev: {
  consul-bin = final.callPackage ../pkgs/consul-bin.nix { };
  create-dmg = final.callPackage ../pkgs/create-dmg.nix { };
  nomad-bin = final.callPackage ../pkgs/nomad-bin.nix { };
  terraform-bin = final.callPackage ../pkgs/terraform-bin.nix { };

  caddy = final.callPackage ../pkgs/caddy.nix { };
}
