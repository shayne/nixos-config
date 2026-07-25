{ lib
, _7zip-zstd
, fetchurl
, stdenv
,
}:

stdenv.mkDerivation {
  pname = "hermes-agent";
  version = "0.0.1";

  src = fetchurl {
    url = "https://hermes-assets.nousresearch.com/Hermes-Setup.dmg?build=413ed6b9df18";
    name = "Hermes-Setup.dmg";
    hash = "sha256-th4Efv4wWfrxxV/sMlLmYfLSqZOno+6/XMapqlwXkPU=";
  };

  nativeBuildInputs = [ _7zip-zstd ];

  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack

    7zz x -sns- "$src"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Hermes.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Desktop installer for Hermes Agent";
    homepage = "https://hermes-agent.nousresearch.com/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
