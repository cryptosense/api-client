#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Generate a version string for use in version substitution in CI.
#
# The first argument should be `github.ref_type` (e.g. `tag` or `branch`). The second
# argument should be `github.ref_name` (e.g. `1.2.3`).

main() {
    local ref_type=$1; shift
    local ref_name=$1; shift

    if [ "$ref_type" = "tag" ]; then
        echo "$ref_name"
    elif [ "$ref_type" = "branch" ]; then
        echo "dev-$(git describe --always HEAD)"
    else
        echo "Unexpected ref_type: $ref_type" >&2
        exit 1
    fi
}

main "$@"
