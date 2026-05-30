{ inputs, ... }:
final: _prev:
{
  tree-sitter-proto = final.tree-sitter.buildGrammar {
    language = "proto";
    version = "0.1.0";
    src = inputs.tree-sitter-proto;
  };
}
