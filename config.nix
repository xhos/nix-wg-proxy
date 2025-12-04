{
  homelab_wg_ip = "10.100.0.10"; # ip of the homelab on the wg network

  tcp_ports = [25];
  tcp_port_ranges = ["35000-35010"];
  udp_ports = [19132];
  udp_port_ranges = ["35000-35010"];

  # optional: preserve client ips for https (requires proxy protocol on homelab)
  # enable_proxy_protocol = true;

  # optional: external:internal mappings
  # tcp_port_mappings = { "25" = 2525; };

  wg_mtu = 1408;
  wg_listen_port = 55055;
  wg_homelab_peer_pubkey = "";

  ssh_authorized_keys = ["your-ssh-public-key"];
}
