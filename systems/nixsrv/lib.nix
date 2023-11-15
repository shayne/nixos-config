{ lib }:
let
  recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
in
{
  mkContainer = defaults: options: recursiveMergeAttrs [
    defaults
    options
    {
      config = args: recursiveMergeAttrs [
        (options.config args)
        (defaults.config args)
      ];
    }
  ];
  mkBinds = paths:
    let
      mapPath = pathStr:
        let
          parts = lib.splitString ":" pathStr;
        in
        {
          "${lib.head parts}" = {
            hostPath = lib.last parts;
            isReadOnly = false;
          };
        };
      mappedPaths = builtins.map mapPath paths;
      mergeAttrs = acc: elem: acc // elem;
    in
    builtins.foldl' mergeAttrs { } mappedPaths;
}
