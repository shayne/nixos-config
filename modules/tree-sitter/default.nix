{ inputs, pkgs, ... }:
{
  # tree-sitter parsers
  xdg.configFile = {
    "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
    "nvim/queries/proto/folds.scm".source =
      "${inputs.tree-sitter-proto}/queries/folds.scm";
    "nvim/queries/proto/highlights.scm".source =
      "${inputs.tree-sitter-proto}/queries/highlights.scm";
    "nvim/queries/proto/textobjects.scm".source =
      ./textobjects.scm;
  };
}
