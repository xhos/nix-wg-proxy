{pkgs, ...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "vps-proxy";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 80 443];
    allowedUDPPorts = [51820];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
      PubkeyAuthentication = true;
    };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [./key.pub];

  environment.systemPackages = with pkgs; [
    wget
    curl
    htop
    iptables
  ];

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "25.05";
}
