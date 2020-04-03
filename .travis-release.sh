set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Build package
opam depext cs_api_client
opam pin add ocaml-conduit
opam pin add ocaml-cohttp
opam pin add .

# Create archive
archive=cs-api-$(git describe --always)-$DISTRO
mkdir "$archive"
cp "$(which cs-api)" "$archive/cs-api"
tar -pcvzf "$archive.tar.gz" "$archive"
