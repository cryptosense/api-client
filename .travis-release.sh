set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Build package
opam pin add --no-action .
opam depext cs_api_client
opam install cs_api_client

# Create archive
archive=cs-api-$(git describe --always)-$DISTRO
mkdir "$archive"
cp "$(which cs-api)" "$archive/cs-api"
tar -pcvzf "$archive.tar.gz" "$archive"
