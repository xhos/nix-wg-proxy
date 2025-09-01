#!/usr/bin/bash

# cleanup
rm -rf result *.qcow2

#build
nix build .#nixosConfigurations.vps-proxy.config.system.build.vm

# run
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-vps-proxy-vm -nographic

