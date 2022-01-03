self: super: {
   openvscode-server = super.openvscode-server.overrideAttrs (oldAttrs: {
     installPhase = super.openvscode-server.installPhase + ''
       sed -i 's/<\/head>/<link type="text\/css" href="https:\/\/fonts.googleapis.com\/css2?family=Fira+Code:wght@300;400;500;600;700\&display=swap" rel="stylesheet"><\/head>/g' $out/libexec/out/vs/code/browser/workbench/workbench.html
       sed -i 's/<\/head>/<link type="text\/css" href="https:\/\/cdn.jsdelivr.net\/gh\/wernight\/powerline-web-fonts@ba4426cb0c0b05eb6cb342c7719776a41e1f2114\/PowerlineFonts.css" rel="stylesheet"><\/head>/g' $out/libexec/out/vs/code/browser/workbench/workbench.html
     '';
  });
}
       # sed -i 's/<\/head>/<meta http-equiv="Content-Security-Policy" content="default-src '\'''self'\'''; font-src '\'''self'\''' https:\/\/fonts.gstatic.com\/; style-src '\'''self'\''' https:\/\/fonts.googleapis.com\/ '\'''unsafe-inline'\''';"><\/head>/g' $out/libexec/out/vs/code/browser/workbench/workbench.html
