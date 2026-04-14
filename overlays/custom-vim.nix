{ inputs, ... }:
final: _prev:
{
  tree-sitter-proto = final.callPackage
    (final.path + /pkgs/development/tools/parsing/tree-sitter/grammar.nix)
    { }
    {
      language = "proto";
      version = "0.1.0";
      src = inputs.tree-sitter-proto;
    };
}
