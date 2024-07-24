#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Fix a ZIP archive by making `cs-api` binaries executable.
#
# This works around the fact that GitHub actions don't preserve the permissions of files
# in their generated ZIPs. See https://github.com/actions/upload-artifact/issues/38.

log() {
    local name="$(basename "$0")"
    echo -e "\033[36;1m[${name%.*}] $*\033[0m" > /dev/stderr
}

main() {
    local path=$1; shift

    log "Create temporary directory"
    local tmp_dir=$(mktemp -d)
    trap "rm -r \"$tmp_dir\"" EXIT

    (
        cd "$tmp_dir"
        log "Extract archive"
        unzip "$path"
        log "Fix binaries"
        find -type f -name 'cs-api' -exec chmod +x {} +
        log "Repack archive"
        zip -r "$path" .
    )

    log "Done"
}

path=$1
main "$path"
