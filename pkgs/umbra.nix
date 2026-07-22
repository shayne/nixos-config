{ lib
, fetchurl
, stdenv
, undmg
,
}:

stdenv.mkDerivation {
  pname = "umbra";
  version = "1.5.1";

  src = fetchurl {
    url = "https://replay-umbra-distribution.s3.amazonaws.com/1-5-1/Umbra.dmg";
    hash = "sha256-i7nbyDd4vEDbjMV8/6MZcnJbmIiB6YdkjYMKzuZ8qLQ=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Umbra.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Menu bar app for switching macOS appearance and wallpapers";
    homepage = "https://replay.software/umbra";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
