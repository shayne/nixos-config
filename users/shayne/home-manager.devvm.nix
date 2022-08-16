{ pkgs, config, lib, ... }: {

  home.packages = [
    pkgs.openvscode-server
  ];

  services.gpg-agent.pinentryFlavor = "tty";

  systemd.user.services."openvscode-server" = {
    Unit.Description = "OpenVSCode Server";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Environment = "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin";
      /*${
        lib.makeBinPath
        (with pkgs; [ coreutils findutils gnugrep gnused systemd ])
      }";*/
      ExecStart = "${pkgs.openvscode-server}/bin/openvscode-server --connectionToken q9UCNzUb";
      Restart = "always";
    };
  };
}

