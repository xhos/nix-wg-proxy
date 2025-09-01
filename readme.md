# proxy

## development

### requirements

nix avelible on the host system

tested to work on nixos, not sure if other distros will

### running locally

build the image:

```shell
nix build .#nixosConfigurations.vps-proxy.config.system.build.vm
```

run it in QEMU:

```shell
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-vps-proxy-vm -nographic
```

then connect to it:

```shell
ssh -p 2222 -i ./key root@localhost
```

