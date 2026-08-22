{ lib
, fetchurl
, stdenv
, undmg
,
}:

stdenv.mkDerivation {
  pname = "nurb";
  version = "0.22.2";

  src = fetchurl {
    url = "https://github.com/Shpigford/nurb/releases/download/v0.22.2/nurb.dmg";
    hash = "sha256-BUg5uibfPst3c00hEXMFu5iZpbxc7trLGHlGzDp2FXE=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R nurb.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Agentic CAD for 3D printing";
    homepage = "https://nurb.dev";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
