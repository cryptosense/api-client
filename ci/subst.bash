#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

log() {
    local name="$(basename "$0")"
    echo -e "\033[36;1m[${name%.*}] $*\033[0m" > /dev/stderr
}

main() {
    local version=$1; shift

    find . -type f -name '*.ml' -exec sed --in-place "s/%%VERSION_NUM%%/$version/g" {} +
}

version=$1
main "$version"
