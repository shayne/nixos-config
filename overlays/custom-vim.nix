_:
final: _prev:
let
  sources = import ../nix/sources.nix;
in
{
  tree-sitter-proto = final.callPackage
    (sources.nixpkgs + /pkgs/development/tools/parsing/tree-sitter/grammar.nix)
    { }
    {
      language = "proto";
      version = "0.1.0";
      source = sources.tree-sitter-proto;
    };
}
