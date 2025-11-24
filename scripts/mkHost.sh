#! /usr/bin/env bash
#                  _                                  _           _
#  ___ ___ ___  __| |_ ___     __    ___ ___ _ _ _   | |_ ___ ___| |_
# |  _|  _| -_||. |  _| -_|   |. |  |   | -_| | | |  |   | . |_ -|  _|
# |___|_| |___|___| | |___|  |___|  |_|_|___|_____|  |_|_|___|___| |
#                 |__|                                           |__|
# ──────────────────────────────────────────────────────────────────────────────
# An automation that will create a new host entry for the current system based
#  on a provided template and command line variables.

set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
    nix run .#mkHost -- <name> <sitename> <username> [--system <x86_64-linux|aarch64-linux>] [--help] [--template <path>] [KEY=VALUE ...]

Arguments:
    <name>      Hostname / machine name (e.g. alfa, bravo, ...)
    <sitename>  Logical site / location name (e.g. theta, ...)
    <username>  User name for the admin user of the new machine

Options:
    -s, --system     Override detected system (default: based on uname -m)
                     Allowed: x86_64-linux, aarch64-linux
    -t, --template   Path to a template file to use instead of /etc/nixos/templates/hosts/default.tmpl
    -p, --purge      Remove a host from the config (only requires positional argument <name>)
    -h, --help       Show this help

Extra template variables:
    Any additional arguments of the form KEY=VALUE after the options will be
    exported to the environment before rendering the template, so they can be
    used as $KEY placeholders inside the template.
EOF
}

info() {
	printf "\e[1;32m[INFO]\e[0m %s\n" "$1"
}

success() {
	printf "\e[1;32m[SUCCESS]\e[0m %s\n" "$1"
}

error() {
	printf "\e[1;31m[ERROR]\e[0m %s\n\n" "$1" >&2
	usage >&2
	exit 1
}

interaction() {
	printf "\e[1;33m[ACTION]\e[0m %s" "$1"
}

warning() {
	printf "\e[1;33m[WARNING]\e[0m %s\n" "$1"
}

promptYes() {
	local msg="$1"
	interaction "$msg [Y/n] "
	read -r answer

	case "${answer:-Y}" in
	[Yy]*)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

promptNo() {
	local msg="$1"
	interaction "$msg [y/N] "
	read -r answer

	case "${answer:-N}" in
	[Yy]*)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

if [[ $# -eq 0 ]]; then
	usage
	exit 0
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

ARCH="$(uname -m)"
case "$ARCH" in
x86_64)
	SYSTEM="x86_64-linux"
	;;
aarch64 | arm64)
	SYSTEM="aarch64-linux"
	;;
*)
	SYSTEM=""
	;;
esac

if [[ $# -lt 1 ]]; then
	error "missing required argument <name>."
fi

PURGE=false
NAME="$1"
shift

if [[ ! "$NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
	error "invalid host name '$NAME'.
        Allowed characters: letters, numbers, dot, underscore, dash."
fi

SITE=""
USER=""

if [[ $# -ge 2 && "$1" != -* && "$2" != -* ]]; then
	SITE="$1"
	USER="$2"
	shift 2
fi

BASE_DIR="/etc/nixos"
HOSTS_DIR="$BASE_DIR/hosts"
TARGET_DIR="${HOSTS_DIR}/${NAME}"
TEMPLATE_FILE="$BASE_DIR/templates/hosts/default.tmpl"
EXTRA_VARS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-p | --purge)
		PURGE=true
		shift
		;;
	-s | --system)
		if [[ $# -lt 2 ]]; then
			error "--system requires an argument."
		fi
		SYSTEM="$2"
		case "$SYSTEM" in
		x86_64-linux | aarch64-linux) ;;
		*)
			error "invalid --system value '$SYSTEM'.
        Allowed: x86_64-linux, aarch64-linux"
			;;
		esac
		shift 2
		;;
	-t | --template)
		if [[ $# -lt 2 ]]; then
			error "--template requires a path argument."
		fi
		TEMPLATE_FILE="$2"
		shift 2
		;;
	-*)
		error "unknown option '$1'."
		;;
	*)
		if [[ "$1" == *=* ]]; then
			key="${1%%=*}"

			case "$key" in
			NAME | SITE | USER | ARCH | SYSTEM | STATE_VERSION | BASE_DIR | HOSTS_DIR | TARGET_DIR | TEMPLATE_FILE | TARGET_FILE | EXTRA_VARS | HOST_ID | PURGE)
				error "extra variable '$key' is reserved and cannot be overridden."
				;;
			esac

			EXTRA_VARS+=("$1")
			shift
		else
			error "unexpected positional argument '$1' after <name> <sitename> <username>."
		fi
		;;
	esac
done

if [[ "$PURGE" == true ]]; then
	if [[ ! -d "$TARGET_DIR" ]]; then
		error "host '$NAME' does not exist at $TARGET_DIR"
	fi

	warning "This will permanently delete the host configuration at $TARGET_DIR"

	if promptNo "Are you sure you want to purge the host '$NAME'?"; then
		sudo rm -rdf "$TARGET_DIR"
		success "host '$NAME' has been purged."
		exit 0
	else
		info "purge aborted."
		exit 0
	fi
fi

if [[ -z "$SITE" || -z "$USER" ]]; then
	error "missing required arguments <sitename> <username> for host creation."
fi

if [[ ! "$SITE" =~ ^[a-zA-Z0-9._-]+$ ]]; then
	error "invalid site name '$SITE'.
Allowed characters: letters, numbers, dot, underscore, dash."
fi

if [[ ! "$USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
	error "invalid username '$USER'.
Allowed pattern: ^[a-z_][a-z0-9_-]*$ (like normal Unix usernames)."
fi

if [[ -z "${SYSTEM:-}" ]]; then
	error "unsupported architecture '$ARCH' from uname -m.
        Please specify --system x86_64-linux or aarch64-linux explicitly."
fi

if [[ -d "$BASE_DIR" ]]; then
	if [[ ! -d "$HOSTS_DIR" ]]; then
		info "creating host directory '$HOSTS_DIR'..."
		sudo mkdir -p "$HOSTS_DIR"
	fi
else
	error "this script must be run on a NixOS system (with '$BASE_DIR' available)."
fi

if [[ -e "$TARGET_DIR" ]]; then
	error "host directory '$TARGET_DIR' already exists."
fi

if [[ ! -e "$BASE_DIR/sites/$SITE" ]]; then
	warning "site $SITE does not exist. Consider running mkSite after this script."
fi

if [[ ! -e "$BASE_DIR/users/$USER" ]]; then
	warning "user $USER does not exist. Consider running mkUser after this script."
fi

sudo mkdir -p "$TARGET_DIR"

if ! command -v nixos-generate-config >/dev/null 2>&1; then
	error "nixos-generate-config not found in PATH.
        This script must be run on a NixOS system (or with nixos-generate-config available)."
fi

info "generating hardware configuration for $NAME..."
sudo nixos-generate-config --show-hardware-config 2>/dev/null |
	sudo tee "${TARGET_DIR}/hardware.nix" >/dev/null

TARGET_FILE="$TARGET_DIR/default.nix"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
	error "template file '$TEMPLATE_FILE' not found."
fi

STATE_VERSION=
if [[ -z "$STATE_VERSION" ]]; then
	if command -v nixos-option >/dev/null 2>&1; then
		v="$(nixos-option system.stateVersion 2>/dev/null |
			sed -nE 's/^[[:space:]]*"([^"]+)".*/\1/p' |
			head -n1)"
		if [[ -n "$v" && "$v" != "null" ]]; then
			STATE_VERSION="$v"
		fi
	fi
fi

if [[ -z "$STATE_VERSION" ]]; then
	if command -v nixos-version >/dev/null 2>&1; then
		v="$(nixos-version | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')"
		if [[ -n "$v" ]]; then
			STATE_VERSION="$v"
		fi
	fi
fi

if [[ -z "$STATE_VERSION" ]]; then
	error "Could not determine system.stateVersion automatically.
        Please set it manually or ensure nixos-option / nixos-version are available."
fi

HOST_ID="$(hexdump -n 4 -e '/4 "%08x"' /dev/urandom | tr 'A-F' 'a-f')"

for kv in "${EXTRA_VARS[@]}"; do
	key=${kv%%=*}
	val=${kv#*=}
	export "$key=$val"
done
export NAME SITE USER STATE_VERSION HOST_ID

if [[ "$TEMPLATE_FILE" == "$BASE_DIR/templates/hosts/default.tmpl" ]]; then
	info "generating configuration for $NAME from default template..."
else
	info "generating configuration for $NAME from template '$TEMPLATE_FILE'..."
fi
if ! command -v envsubst >/dev/null 2>&1; then
	error "envsubst (from gettext) not found in PATH.
        Install gettext or run this script via 'nix run .#mkHost' so it's provided."
fi
envsubst <"$TEMPLATE_FILE" | sudo tee "$TARGET_FILE" >/dev/null

success "successfully generated a new config for $NAME."
if promptYes "do you want to edit it now?"; then
	sudo -E "${EDITOR:-vim}" "$TARGET_FILE"
fi
