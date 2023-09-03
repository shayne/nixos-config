/* This contains various packages we want to overlay. Note that the
 * other ".nix" files in this directory are automatically loaded.
 */
final: _prev: {
  caddy = final.callPackage ../pkgs/caddy.nix { };
}
