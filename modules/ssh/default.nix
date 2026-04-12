_:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      "orb" = {
        hostname = "localhost";
        user = "default";
        port = 32222;
        identityFile = "~/.orbstack/ssh/id_ed25519";
      };
    };
  };
}
