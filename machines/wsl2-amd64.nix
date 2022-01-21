{ config, pkgs, lib, modulesPath, ... }:

let
  defaultUser = "shayne";
  automountPath = "/mnt";
  syschdemd = import ./syschdemd.nix { inherit lib pkgs config defaultUser; };
  inherit (pkgs.stringsWithDeps) stringAfter;
in
{
  environment.sessionVariables.NIXNAME = "wsl2-amd64";

  # imports = [
  #   "${modulesPath}/profiles/minimal.nix"
  # ];

  # use unstable nix so we can access flakes
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };


  # Set your time zone.
  time.timeZone = "America/New_York";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    niv
    wget
  ];

  hardware.opengl = {
    enable = true;
    # extraPackages = with pkgs; [
    #   libGL
    # ];
    # setLdLibraryPath = true;
  };

  # WSL is closer to a container than anything else
  boot.isContainer = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  environment.extraInit = ''PATH="$PATH:$WSLPATH"'';

  environment.etc.hosts.enable = false;
  environment.etc."resolv.conf".enable = false;

  networking.dhcpcd.enable = false;

  users.users.${defaultUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.root = {
    shell = "${syschdemd}/bin/syschdemd";
    # Otherwise WSL fails to login as root with "initgroups failed 5"
    extraGroups = [ "root" ];
  };

  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.
  fonts = {
    fontDir.enable = true;

    fonts = [
      (builtins.path {
        name = "custom-fonts";
        path = ../secret/fonts;
        recursive = true;
      })
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable systemd units that don't make sense on WSL
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  systemd.services.firewall.enable = false;
  systemd.services.systemd-resolved.enable = false;
  systemd.services.systemd-udevd.enable = false;

  # Don't allow emergency mode, because we don't have a console.
  systemd.enableEmergencyMode = false;

  environment.etc."wsl.conf".text = ''
    [automount]
    enabled=true
    mountFsTab=true
    root=${automountPath}/
    options=metadata,uid=1000,gid=100
  '';

  system.activationScripts = {
    copy-launchers = stringAfter [] ''
      mkdir -p /usr/share/applications
      for x in applications icons; do
        echo "Copying /usr/share/$x"
        ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
      done
    '';
  };
}
