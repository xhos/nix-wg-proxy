{
  lib,
  pkgs,
  ...
}: let
  config = {
    homelab_ip = "10.100.0.2";

    tcp_ports = [80 443 25];
    tcp_port_ranges = ["35000-35010"];

    udp_ports = [];
    udp_port_ranges = [];

    wg_vps_addr_cidr = "10.100.0.1/24";
    wg_homelab_peer_ip = "10.100.0.2/32";
    wg_listen_port = 55055;
    wg_mtu = 1408;

    wg_private_key_path = "/var/lib/wireguard/private.key";
    wg_homelab_peer_pubkey = "your-public-homelab-key";
    ssh_authorized_keys = ["your ssh public key"];

    host_name = "vps-proxy";
    time_zone = "UTC";
  };

  # helpers
  mkPortSet = ports: "{ " + lib.concatStringsSep ", " (map toString ports) + " }";
  
  tcp_set = mkPortSet config.tcp_ports;
  udp_set = mkPortSet config.udp_ports;
  
  have_tcp = config.tcp_ports != [];
  have_udp = config.udp_ports != [];
  have_tcp_ranges = config.tcp_port_ranges != [];
  have_udp_ranges = config.udp_port_ranges != [];

  mkPortRanges = ranges: proto: 
    lib.concatMapStringsSep "\n          " 
      (range: "${proto} dport ${range} dnat to ${config.homelab_ip}") 
      ranges;
in {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
    kernel.sysctl."net.ipv4.ip_forward" = 1;
  };

  networking = {
    hostName = config.host_name;
    
    nftables = {
      enable = true;
      tables.nat = {
        family = "ip";
        content = ''
          chain prerouting {
            type nat hook prerouting priority -100; policy accept;
            ${lib.optionalString have_tcp "tcp dport ${tcp_set} dnat to ${config.homelab_ip}"}
            ${lib.optionalString have_tcp_ranges (mkPortRanges config.tcp_port_ranges "tcp")}
            ${lib.optionalString have_udp "udp dport ${udp_set} dnat to ${config.homelab_ip}"}
            ${lib.optionalString have_udp_ranges (mkPortRanges config.udp_port_ranges "udp")}
          }
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "wg0" masquerade
            iifname "wg0" oifname "eth0" masquerade
          }
        '';
      };
    };

    firewall = {
      enable = true;
      trustedInterfaces = ["wg0"];
      allowedTCPPorts = [22] ++ config.tcp_ports;
      allowedUDPPorts = [config.wg_listen_port] ++ config.udp_ports;
      allowedTCPPortRanges = map (range: 
        let parts = lib.splitString "-" range;
        in { from = lib.toInt (builtins.elemAt parts 0); to = lib.toInt (builtins.elemAt parts 1); }
      ) config.tcp_port_ranges;
      allowedUDPPortRanges = map (range: 
        let parts = lib.splitString "-" range;
        in { from = lib.toInt (builtins.elemAt parts 0); to = lib.toInt (builtins.elemAt parts 1); }
      ) config.udp_port_ranges;
    };

    wireguard.interfaces.wg0 = {
      mtu = config.wg_mtu;
      ips = [config.wg_vps_addr_cidr];
      listenPort = config.wg_listen_port;
      privateKeyFile = config.wg_private_key_path;
      generatePrivateKeyFile = true;
      peers = [{
        publicKey = config.wg_homelab_peer_pubkey;
        allowedIPs = [config.wg_homelab_peer_ip];
      }];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = config.ssh_authorized_keys;

  system.activationScripts.show-wireguard-key = ''
    if [ -f ${lib.escapeShellArg config.wg_private_key_path} ]; then
      echo "========================================="
      echo "vps wireguard public key:"
      ${pkgs.wireguard-tools}/bin/wg pubkey < ${lib.escapeShellArg config.wg_private_key_path}
      echo "add this to your homelab peer"
      echo "========================================="
    fi
  '';

  time.timeZone = config.time_zone;
  i18n.defaultLocale = "en_US.UTF-8";
  
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [pkgs.wireguard-tools];

  system.stateVersion = "25.05";
}