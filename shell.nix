# Shell for bootstrapping flake-enabled nix and home-manager
# Enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? import ./nixpkgs.nix {} }:

pkgs.mkShell {
  # Enable experimental features without having to specify the argument
  NIX_CONFIG = "experimental-features = nix-command flakes";
  nativeBuildInputs = with pkgs; [ colmena home-manager git ];
  
  buildInputs = with pkgs; [
    # Random test packages
    cowsay
    fortune
    lolcat
    figlet
    
    # More test dependencies
    tree
    jq
    yq-go
  ];
  
  shellHook = ''
    echo "Random test environment loaded!"
    cowsay "Hello from the random test shell"
  '';
}
