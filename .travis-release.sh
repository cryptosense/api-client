set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

archive=cs-api-$(git describe --always)-$DISTRO
mkdir "$archive"
cp _build/install/default/bin/cs-api "$archive/cs-api"
tar -pcvzf "$archive.tar.gz" "$archive"
