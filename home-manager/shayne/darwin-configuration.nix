{
  programs.fish = {
    shellAliases = {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    } // (import ../lib/shellAliases.enc.nix);
  };
}
