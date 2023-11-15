#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

main() {
    local version=$1; shift
    local dest=$1; shift

    local image_tag="cs-api"
    local container_name="cs-api"

    local tmp=$(mktemp --directory)
    local archive="cs-api-$version-centos-7"
    mkdir "$tmp/$archive"

    docker build \
      --build-arg DISTRIB=centos-7-ocaml-4.14 \
      --build-arg OCAML_VERSION=4.14 \
      --build-arg VERSION=$version \
      --tag "$image_tag" \
      .
    docker create --name "$container_name" "$image_tag"
    docker cp \
        --follow-link \
        "$container_name:/home/opam/workdir/_build/install/default/bin/cs-api" \
        "$tmp/$archive/cs-api"
    docker rm "$container_name"

    chmod 755 "$tmp/$archive/cs-api"
    (cd "$tmp" && tar pcvzf "$archive.tar.gz" "$archive")
    mv "$tmp/$archive.tar.gz" "$dest/"
    rm -rf "$tmp"
}

version=$1; shift
dest=$1; shift
main "$version" "$dest"
