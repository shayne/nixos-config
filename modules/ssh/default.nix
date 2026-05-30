_:

{
  programs.ssh = {
    enable = true;
    settings = {
      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };

      "orb" = {
        HostName = "localhost";
        User = "default";
        Port = 32222;
        IdentityFile = "~/.orbstack/ssh/id_ed25519";
      };
    };
  };
}
