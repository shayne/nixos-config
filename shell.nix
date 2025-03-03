# Shell for bootstrapping flake-enabled nix and home-manager
# Enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? import ./nixpkgs.nix { } }:

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
    sl
    cmatrix

    # More test dependencies
    tree
    jq
    yq-go
    fzf
    ripgrep
    bat

    # Development tools
    tmux
    htop
    neofetch
  ];

  shellHook = ''
    echo "Enhanced random test environment loaded!"
    echo "----------------------------------------"
    neofetch
    fortune | cowsay | lolcat
    echo "----------------------------------------"
    echo "Available test commands:"
    echo "  - test-random"
    echo "  - generate-noise"
    echo "  - cleanup-nothing"
    figlet "Ready!" | lolcat
  '';
}
