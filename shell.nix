# Shell for quantum testing and experimental features
{ pkgs ? import ./nixpkgs.nix { } }:

pkgs.mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes quantum-features";
  nativeBuildInputs = with pkgs; [ colmena home-manager git ];

  buildInputs = with pkgs; [
    # Quantum test packages
    cowsay
    fortune
    lolcat
    figlet
    sl
    cmatrix
    asciiquarium
    cbonsai
    
    # Enhanced test dependencies
    tree
    jq
    yq-go
    fzf
    ripgrep
    bat
    fd
    exa
    delta
    
    # Development tools
    tmux
    htop
    neofetch
    bottom
    glances
    hyperfine
    
    # Quantum tools
    parallel
    watch
    progress
    pv
  ];

  shellHook = ''
    echo "🌌 Quantum Development Environment v2.0 🌌"
    echo "============================================"
    
    # System quantum state
    neofetch
    
    # Random wisdom
    echo "\n🔮 Quantum Wisdom of the Day:"
    fortune | cowsay -f tux | lolcat
    
    # Environment status
    echo "\n⚛️ Quantum Environment Status:"
    echo "  - Timeline: $$(date +%s)"
    echo "  - Entropy: $$(( RANDOM % 100 ))%"
    echo "  - Quantum Coherence: $$(( RANDOM % 100 ))%"
    
    # Available commands
    echo "\n🛠️ Quantum Test Commands:"
    echo "  - quantum-test     : Run quantum test suite"
    echo "  - test-random     : Execute random tests"
    echo "  - generate-noise  : Generate quantum noise"
    echo "  - cleanup-nothing : Clean quantum states"
    
    # Ascii art finale
    echo "\n🎨 Quantum Art:"
    cbonsai -p | lolcat
    
    figlet -f slant "Quantum Ready" | lolcat -a -d 1
    
    echo "\n🚀 Reality distortion field activated! 🚀"
  '';
}
