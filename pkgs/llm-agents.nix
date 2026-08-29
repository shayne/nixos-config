# Shared expression building the numtide/llm-agents.nix package tree
# (hermes-agent, pi, amp, omop, ...) against nixpkgs-unstable.
#
# The `llm-agents` flake input exports a `shared-nixpkgs` overlay that builds
# the package tree against a consumer-provided package set. We build against
# nixpkgs-unstable instead of the system's release nixpkgs, because the tree
# references packages (e.g. python3.pkgs.pyprojectVersionPatchHook) that do not
# exist in the release channel yet.
#
# NOTE: the flake-native `llm-agents.packages.<system>."hermes-agent"` output
# does NOT evaluate on darwin (its nixpkgs pins hit the jaraco-path broken
# mark worked around below), so everything in this repo sources the hermes
# package from this expression, not from the flake's `packages` output.
#
# Darwin workarounds for jaraco-path (pulled in by hermes' python3.14 deps):
# - It is marked broken on darwin because its wheel METADATA declares pyobjc,
#   which nixpkgs does not ship for darwin. The eval-time problem mark is
#   ignored via config.problems.handlers below.
# - It is redefined via pythonPackagesExtensions with dontCheckRuntimeDeps so
#   the build-time runtime dependency check does not fail (hermes only uses
#   its path helpers).
# - pythonPackagesExtensions is the supported hook for overriding python
#   packages; plain `pkg.override` with new attributes does not work in this
#   nixpkgs generation.
{ inputs, pkgs }:

(import inputs.nixpkgs-unstable {
  inherit (pkgs.stdenv.hostPlatform) system;
  config = {
    allowUnfree = true;
    problems.handlers = {
      "jaraco-path" = { broken = "ignore"; };
    };
  };
  overlays = [
    inputs.llm-agents.overlays.shared-nixpkgs
    (_final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pythonFinal: pythonPrev: {
          jaraco-path = pythonFinal.buildPythonPackage {
            pname = "jaraco-path";
            version = "3.7.2";
            pyproject = true;
            dontCheckRuntimeDeps = true;
            src = pythonPrev."jaraco-path".src;
            build-system = [ pythonFinal.setuptools-scm ];
            pythonImportsCheck = [ "jaraco.path" ];
            meta = pythonPrev."jaraco-path".meta;
          };
        })
      ];
    })
  ];
}).llm-agents
