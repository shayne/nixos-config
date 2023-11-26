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
}
