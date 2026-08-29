# Hermes Agent (https://hermes-agent.nousresearch.com) — nix-built + Computer Use
#
# Installs Hermes from the pinned numtide/llm-agents.nix flake via the
# shared-nixpkgs overlay build in pkgs/llm-agents.nix (nixpkgs-unstable
# + jaraco-path darwin workaround — the flake-native `packages` output for
# hermes does not evaluate on darwin), and wraps it so the Nix-sealed build
# is complete on this machine:
#
# * `httpx2` — the MCP 2.x HTTP stack Hermes' `computer_use` backend
#   imports — is missing from the nix build's runtime python env (the build
#   ships `mcp` 1.29 + `starlette` but not `httpx2`), and the nix build
#   seals lazy pip installs (HERMES_DISABLE_LAZY_INSTALLS=1 in its launcher).
#   We append a python env carrying `httpx2` (from the pinned
#   nixpkgs-unstable, same python 3.14 interpreter as the nix build) to
#   PYTHONPATH. Verified: the env's 23 other packages are all
#   version-identical to the build's runtime env, so the append can only
#   ADD modules (httpx2, httpcore2, pyopenssl, trustme, truststore) and can
#   never shadow the agent's own site-packages.
# * `HERMES_LAZY_INSTALL_TARGET=~/.hermes/lazy-packages` — the sealed build
#   still has to *fail fast* for genuinely missing future deps unless a
#   writable durable target is configured; with it set, Hermes redirects any
#   future lazy install into the user-owned dir and activates it on
#   sys.path, and `uv` (put on PATH by this wrapper) performs the install.
# * `HERMES_CUA_DRIVER_CMD` — points at the TCC-identified CuaDriver.app
#   bundle binary. The bundle is installed declaratively from the pinned
#   upstream release (pkgs/cua-driver.nix) in place of the imperative
#   installer: the activation script below replaces /Applications/CuaDriver.app
#   in place (same code signature per release), so the Accessibility /
#   Screen Recording grants macOS TCC recorded for com.trycua.driver
#   survive. If you ever upgrade to a release whose code signature changes,
#   re-grant both in System Settings → Privacy & Security.
#
# Hermes continues to own all mutable state under ~/.hermes (config.yaml,
# .env with API keys, sessions, skills, auth.json).
{ config, inputs, lib, pkgs, ... }:

let
  # hostPlatform is a platform object (usable as a flake `packages` key, as
  # the pi module does).
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # Overlay build against nixpkgs-unstable (repo pkgs/, via shared expr).
  llmAgents = import ../../../pkgs/llm-agents.nix { inherit inputs pkgs; };
  hermesPackage = llmAgents."hermes-agent";

  cuaDriver = pkgs.cua-driver;

  # python env carrying httpx2 (and its deps) for Hermes' runtime
  # interpreter. Sourced from `pkgs.unstable` — the repo's standard
  # nixpkgs-unstable instance (overlays/unstable-packages, same pinned rev
  # the llm-agents overlay build uses) — so it is the same python 3.14.7
  # interpreter as the nix build. (A raw `import inputs.nixpkgs-unstable`
  # here fails to evaluate inside the home-manager module context.)
  #
  # `env.sitePackages` is a *subpath reference* that toString()s to the
  # relative `lib/python3.14/site-packages`, so build the absolute path
  # from the env's store path + the interpreter's minor version.
  unstablePy = pkgs.unstable.python3;
  httpx2Env = unstablePy.withPackages (ps: [ ps.httpx2 ]);
  httpx2SitePackages =
    "${httpx2Env.outPath}/lib/python${
      builtins.concatStringsSep "."
      (lib.take 2 (lib.splitString "." unstablePy.version))
    }/site-packages";

  hermesWrapper = pkgs.writeShellApplication {
    name = "hermes";
    runtimeInputs = [ hermesPackage pkgs.uv ];
    text = ''
      # MCP HTTP stack the nix build lacks (see module header). Appended,
      # never prepended: the agent's own site-packages wins on collision.
      export PYTHONPATH="''${PYTHONPATH:+''${PYTHONPATH}:}${httpx2SitePackages}"

      # The launcher seals the agent venv against lazy pip installs;
      # declare this a nix-managed install with a writable durable target so
      # any future missing dependency installs into the user-owned dir and
      # activates on sys.path instead of failing against the read-only store.
      export HERMES_MANAGED=nix
      export HERMES_LAZY_INSTALL_TARGET="''${HOME}/.hermes/lazy-packages"

      # Computer Use driver: point explicitly at the app-bundle binary
      # (stable TCC identity) when present. Left unset otherwise so Hermes
      # falls back to PATH / canonical install locations.
      if [ -x "$HOME/Applications/CuaDriver.app/Contents/MacOS/cua-driver" ]; then
        export HERMES_CUA_DRIVER_CMD="$HOME/Applications/CuaDriver.app/Contents/MacOS/cua-driver"
      elif [ -x "/Applications/CuaDriver.app/Contents/MacOS/cua-driver" ]; then
        export HERMES_CUA_DRIVER_CMD="/Applications/CuaDriver.app/Contents/MacOS/cua-driver"
      fi

      exec ${lib.getExe hermesPackage} "$@"
    '';
  };
in
{
  # Hermes + wrapper on every host (matches the former modules/llm-agents.nix,
  # which installed the agent unconditionally). Only the Computer Use driver
  # package and its activation scripts are darwin-specific.
  home = {
    packages = [ hermesWrapper ] ++ lib.optionals isDarwin [ cuaDriver ];

    activation = {
      hermesLazyPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.home.homeDirectory}/.hermes/lazy-packages"
        run chmod 700 "${config.home.homeDirectory}/.hermes/lazy-packages"
      '';

      # Keep the TCC-identified app bundle at a stable location. Replacing
      # /Applications/CuaDriver.app in place preserves the Accessibility /
      # Screen Recording grants (same code signature per release); on hosts
      # where /Applications is not writable, fall back to a user-local bundle.
      # After an upgrade that changes the code signature, re-grant TCC in
      # System Settings -> Privacy & Security.
      cuaDriverApp = lib.hm.dag.entryAfter [ "writeBoundary" ]
        (lib.optionalString isDarwin ''
          system_app=/Applications/CuaDriver.app
          user_app="${config.home.homeDirectory}/Applications/CuaDriver.app"

          make_bundle_writable() {
            local target="$1"
            if [ -d "$target" ] && [ ! -L "$target" ]; then
              run chmod -R u+w "$target"
            fi
          }

          if [ -w /Applications ]; then
            staging_app=/Applications/.CuaDriver.app.home-manager-tmp
            make_bundle_writable "$staging_app"
            run rm -rf "$staging_app"
            run cp -R ${cuaDriver}/CuaDriver.app "$staging_app"
            run chmod -R u+w "$staging_app"
            make_bundle_writable "$system_app"
            run rm -rf "$system_app"
            run mv "$staging_app" "$system_app"
            make_bundle_writable "$user_app"
            run rm -rf "$user_app"
          else
            run mkdir -p "${config.home.homeDirectory}/Applications"
            make_bundle_writable "$user_app"
            run rm -rf "$user_app"
            run ln -s ${cuaDriver}/CuaDriver.app "$user_app"
          fi
        '');
    };
  };
}
