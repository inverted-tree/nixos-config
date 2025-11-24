<div align="center">
    <h1>my NixOS configurations.</h1>
    <p>This repo stores all my nix configurations. It is modular in terms of host machines, modules and users. The main branch is a rolling release.</p>
</div>

<div align="center">
    <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-colours.svg" width="128" />
</div>

> [!NOTE]
> Disk partitioning still needs to be done manually for each machine. I did not yet have the nerve to make this declarative.

# Setting up a new host

To bootstrap a new machine with the configuration from withing the installer, follow the [official installation guide](https://nixos.wiki/wiki/NixOS_Installation_Guide) up to the *Create NixOS Config* section, or just:

- Make sure networking is working:

```sh
ping -c 2 papertoilet.com
```

- Make sure all disks are correctly formatted and mounted:

```sh
lsblk -f
```

- Then, after nix flakes are enabled:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

- Clone this repo:

```sh
nix-shell -p git vim
git clone https://github.com/inverted-tree/nixos-config.git /mnt/etc/nixos
```

- and generate a host configuration:

```sh
nix run .#mkHost -- <hostname> <sitename> <username>
```

- Adapt the generated config:

```sh
vim /mnt/etc/nixos/hosts/<newhostname>/default.nix
```

- and then install the OS:

```sh
nixos-install --flake /mnt/etc/nixos#<hostname>
```

- Finally, set a root password and reboot.

> [!NOTE]
> After the installation has finished and the system has rebooted, sync the [dotfiles](https://github.com/inverted-tree/dotfiles). Instructions on how to sync them are in the repo's [readme](https://github.com/inverted-tree/dotfiles/blob/main/README.md).

---

> [!WARNING]
> This works on my machine — and since it’s Nix, it should work on yours too.
> No promises, no warranties, no sacrificial goats. See [LICENSE](./LICENSE).
