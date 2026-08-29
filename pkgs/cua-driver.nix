# cua-driver — background desktop driver used by Hermes' Computer Use backend.
#
# Sources:
#   https://github.com/trycua/cua (MIT)
#   Releases: https://github.com/trycua/cua/releases
#
# The darwin-universal tarball bundles both the standalone `cua-driver`
# binary and the `CuaDriver.app` app bundle. On macOS the MCP session runs
# inside the app bundle because TCC grants Accessibility/Screen-Recording
# to the responsible app (com.trycua.driver); the bare binary is still
# kept on PATH for `hermes computer-use doctor` and manual use.
#
# To upgrade: bump the version + sha256 below (sha256 from the release's
# checksums.txt, asset `cua-driver-rs-<v>-darwin-universal.tar.gz`).
{ lib
, stdenvNoCC
, fetchurl
}:

let
  version = "0.22.2";
in
stdenvNoCC.mkDerivation {
  pname = "cua-driver";
  inherit version;
  src = fetchurl {
    url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${version}/cua-driver-rs-${version}-darwin-universal.tar.gz";
    sha256 = "a9ca5891386a3a50b595b53329127e18b0326ce1cefd4e8dcd16efff0e58f4cc";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    # tarball unpacks to cua-driver-rs-<v>-darwin-universal/
    tar -xzf $src -C $TMPDIR
    dist=$(find $TMPDIR -maxdepth 1 -type d -name 'cua-driver-rs-*' | head -n1)

    # App bundle (TCC-identified binary for Accessibility / Screen Recording)
    mkdir -p $out/bin
    cp -R $dist/CuaDriver.app $out/CuaDriver.app

    # Standalone binary for PATH; needs no custom rpaths (only links the
    # system Swift concurrency runtime at /usr/lib/swift).
    install -m 0755 $dist/cua-driver $out/bin/cua-driver

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cross-platform background computer-use driver (Hermes Computer Use backend)";
    homepage = "https://github.com/trycua/cua";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "cua-driver";
  };
}
