<div align="center">
    <h1>my NixOS configurations.</h1>
    <p>This repo stores all my nix configurations. It is modular in terms of host machines, modules and users. The main branch should be regarded as a rolling release.</p>
</div>

> [!NOTE]
> Disk partitioning still needs to be done manually for each machine. I did not yet have the nerve to make this declarative.

# Setting up a new host
To bootstrap a new machine with the configuration from withing the installer, follow the [official installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide) up to the *Create NixOS Config* section, or just:
- make sure networking is working:
```sh
ping -c 2 papertoilet.com
```
- make sure all disks are correctly formatted and mounted:
```sh
lsblk -f
```

Then, after nix flakes are enabled:
```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

clone this repo:
```sh
nix-shell -p git vim
git clone https://github.com/inverted-tree/nixos-config.git /mnt/etc/nixos
```

and generate the `hardware-configuration.nix`:
```sh
nixos-generate-config --root /mnt
mkdir -p /mnt/etc/nixos/hosts/<newhostname>
mv /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/<newhostname>
```

Adapt the generated config:
```sh
vim /mnt/etc/nixos/hosts/<newhostname>/configuration.nix
```

it should look something like [the default template](./hosts/templates/default-configuration.nix):
```nix
{
  imports = [
    # The hardware-dependent options
    ./hardware-configuration.nix
    # All (shared/non-specific) users
    ../../users/iamgroot.nix
    # All custom modules
    ../../modules/somemodule.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  ...
}
```

and then install the OS wiht the flake:
```sh
nixos-install --flake /mnt/etc/nixos#<newhostname>
```

Finally, set a root password and reboot.

---

> [!WARNING]
> This repo mainly acts as a way to sync my configurations across host machines and make it easy to set up a new machine with minimal effort. Feel free to use my code and break your system. 
