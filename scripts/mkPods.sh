#! /usr/bin/env bash
# .                _                                            _
#  ___ ___ ___  __| |_ ___     __    ___ ___ _ _ _    ___ ___ _| |
# |  _|  _| -_||. |  _| -_|   |. |  |   | -_| | | |  | . | . | . |
# |___|_| |___|___| | |___|  |___|  |_|_|___|_____|  |  _|___|___|
# .               |__|                               |_|
# ──────────────────────────────────────────────────────────────────────────────
# An automation that will create a new container service based on a
#  docker-compose.yml file. Since most services are available as a docker
#  container and offer an example compose file, this automation removes the
#  friction in setting up a new service in a nix-native way.

set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
    nix run .#mkPods -- [<docker-compose.yml>] [--help] [--output]

Arguments:
    <docker-compose.yml>   Docker compose file to read. If omitted, the file is
                           read from stdin. Use "-" explicitly to force stdin.

Options:
    -h, --help     Show this help
	-o, --output   Write the generated module to this path.
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

tmpdir=""
cleanup() {
        if [[ -n "${tmpdir:-}" && -d "${tmpdir:-}" ]]; then
                rm -rf "$tmpdir"
        fi
}
trap cleanup EXIT


if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

COMPOSE_FILE=""
OUTPUT_FILE="docker-compose.nix"

while [[ $# -gt 0 ]]; do
        case "$1" in
        -h|--help)
                usage
                exit 0
                ;;
        -o|--output)
                [[ -n "${2:-}" ]] || error "--output requires a path"
                OUTPUT_FILE="$2"
                shift 2
                ;;
        -*)
                error "Unknown option: $1"
                ;;
        *)
                if [[ -n "$COMPOSE_FILE" ]]; then
                        error "Only one compose file may be specified"
                fi
                COMPOSE_FILE="$1"
                shift
                ;;
        esac
done

if [[ -z "$COMPOSE_FILE" || "$COMPOSE_FILE" == "-" ]]; then
        if [[ -t 0 ]]; then
                error "No compose file provided and no stdin detected"
        fi

        info "Reading docker-compose.yml from stdin..."
        tmpdir="$(mktemp -d)"
        COMPOSE_FILE="$tmpdir/docker-compose.yml"
        cat >"$COMPOSE_FILE"
else
        [[ -r "$COMPOSE_FILE" ]] || error "Compose file '$COMPOSE_FILE' not readable"
fi

if ! command -v compose2nix >/dev/null 2>&1; then
        error "compose2nix not found. Run this script with 'nix run .#mkPods' to resolve dependencies."
fi

OUTPUT_FILE="docker-compose.nix"

info "Generating Nix module from '$COMPOSE_FILE'..."
sudo compose2nix -inputs "$COMPOSE_FILE" -output "$OUTPUT_FILE" -runtime "podman" -auto_format

if promptYes "do you want to edit it now?"; then
	sudo -E "${EDITOR:-vim}" "$OUTPUT_FILE"
fi

success "Nix module written to: $OUTPUT_FILE"
