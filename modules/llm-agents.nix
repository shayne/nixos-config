# AI agent packages from llm-agents.nix (https://github.com/numtide/llm-agents.nix):
# hermes-agent, amp, omop, and friends.
#
# The `llm-agents` flake input exports a `shared-nixpkgs` overlay that builds the
# package tree against the consumer's package set. We build against
# nixpkgs-unstable instead of the system's release nixpkgs, because the tree
# references packages (e.g. python3.pkgs.pyprojectVersionPatchHook) that do not
# exist in the release channel yet.
#
# Darwin workarounds for jaraco-path (pulled in by hermes' python3.14 deps):
# - It is marked broken on darwin because its wheel METADATA declares pyobjc,
#   which nixpkgs does not ship for darwin. The eval-time problem mark is
#   ignored via config.problems.handlers below.
# - It is redefined via pythonPackagesExtensions with dontCheckRuntimeDeps so
#   the build-time runtime dependency check does not fail (hermes only uses
#   its path helpers).
#
# Provides `config.llmAgents`, the full package set.
{ inputs, pkgs, ... }:

{
  llmAgents =
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
    }).llm-agents;
}
