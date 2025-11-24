#! /usr/bin/env bash
#                  _                                      _ _
#  ___ ___ ___  __| |_ ___     __    ___ ___ _ _ _    ___|_| |_ ___
# |  _|  _| -_||. |  _| -_|   |. |  |   | -_| | | |  |_ -| |  _| -_|
# |___|_| |___|___| | |___|  |___|  |_|_|___|_____|  |___|_| | |___|
#                 |__|                                     |__|
# ──────────────────────────────────────────────────────────────────────────────
# An automation that will create a new site entry based on a provided template
#  and command line variables.

set -euo pipefail

usage() {
	return
}

info() {
	printf "\e[1;32m[INFO]\e[0m %s\n" "$1"
}

error() {
	printf "\e[1;31m[ERROR]\e[0m %s\n\n" "$1" >&2
	usage >&2
	exit 1
}

interaction() {
	printf "\e[1;33m[ACTION]\e[0m %s" "$1"
}

prompt() {
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

error "mkSite: not implemented yet."
