# Scripts – Infrastructure Generators

This directory contains helper scripts that generate and manage parts of the NixOS infrastructure in a reproducible and opinionated (but extensible) way. These tools are designed to be used through the flake (`nix run`) so that all runtime dependencies are provided automatically.

---

## Overview

| Script                               | Purpose                                                         | Status              |
| ------------------------------------ | --------------------------------------------------------------- | ------------------- |
| [`mkHost`](#mkHost – Host Generator) | Create or remove a host configuration under `/etc/nixos/hosts/` | Implemented         |
| [`mkSite`](#mkSite – Site Generator) | Create site definitions (location / environment grouping)       | Not yet implemented |
| [`mkUser`](#mkUser – User Generator) | Create user definitions shared across hosts                     | Not yet implemented |

---

## mkHost – Host Generator

`mkHost` automates the creation and removal of host configurations for NixOS systems.

It will:

* Create the host directory and configuration files
* Generate hardware configuration using nixos-generate-config
* Render default.nix from a template

### Basic usage

```
nix run .#mkHost -- <name> <sitename> <username> [options] [KEY=VALUE ...]
```

### Examples

Create a new host:

```
nix run .#mkHost -- wopr cmc falken
```

Create a host with extra template variables:

```
nix run .#mkHost -- wopr cmc falken GAME="Falken's Maze"
```

Use a custom template:

```
nix run .#mkHost -- wopr cmc falken --template /etc/nixos/templates/hosts/custom.tmpl
```

Purge an existing host (removes directory + git tracking if present):

```
nix run .#mkHost -- wopr --purge
```

### Supported options

| Option             | Description                                                           |
| ------------------ | --------------------------------------------------------------------- |
| `-s`, `--system`   | Override detected system architecture (x86_64-linux or aarch64-linux) |
| `-t`, `--template` | Path to a custom host template file                                   |
| `-p`, `--purge`    | Remove an existing host and its tracked git files                     |
| `-h`, `--help`     | Show usage information                                                |

### Template variables

The default template supports these built-in variables:

* `$NAME`
* `$SITE`
* `$USER`
* `$STATE_VERSION`
* `$HOST_ID`
* `$SYSTEM`

They are populated based on the provided arguments. One can define additional variables via:

```
KEY=value
```

> [!NOTE]  
> Additional arguments will be exported and substituted using `envsubst`. Thus, they will only have effect in a custom template since there are no other substitutions available in the [default template](../templates/hosts/default.tmpl).

---

## mkSite – Site Generator

This script will manage logical site definitions such as:

* Locations (`homelab`, `cmc`, `office`)
* Environment groupings
* Shared networking or policy layers

### Planned goals

* Create `/etc/nixos/sites/<site>`
* Generate site-level configuration boilerplate
* Integrate with flake and colmena structure

> [!IMPORTANT]  
> Status:  Not implemented yet

---

## mkUser – User Generator

This script will manage shared user definitions for hosts.

### Planned goals

* Create `/etc/nixos/users/<user>`
* Generate declarative user configs
* Support SSH keys, roles, and group memberships
* Template-driven design

> [!IMPORTANT]  
> Status:  Not implemented yet

---

## Recommended usage

Use these scripts via nix to ensure reproducibility and correct dependencies:

```
nix run .#mkHost -- ...
```

or enter the development shell:

```
nix develop .#mkTools
```

---

If you expand the system (more sites, users, machines), these scripts form the foundation of a scalable homelab or production-style workflow.

