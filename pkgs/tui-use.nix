{ buildNpmPackage
, fetchurl
, lib
}:

buildNpmPackage rec {
  pname = "tui-use";
  version = "0.1.17";

  src = fetchurl {
    url = "https://registry.npmjs.org/tui-use/-/tui-use-${version}.tgz";
    hash = "sha256-KSUzYmMFOK4wIsHln4LWhHWpQfB8LF1IrM3j8pVUvYk=";
  };

  npmDepsHash = "sha256-MbIaWnc9UI2Q6feHcftghQA0tFrnmligZoAsIkB6QHA=";

  postPatch = ''
    cp ${./tui-use/package.json} package.json
    cp ${./tui-use/package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  npmInstallFlags = [
    "--omit=dev"
  ];

  meta = {
    description = "TUI automation for AI agents";
    homepage = "https://www.npmjs.com/package/tui-use";
    license = lib.licenses.mit;
    mainProgram = "tui-use";
    platforms = lib.platforms.all;
  };
}
