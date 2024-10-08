# Base image for Debian-based distributions (e.g. `debian:10` or `ubuntu:18.04`)
ARG DEBIAN_BASE=ubuntu:18.04

# Base image for CentOS-based distributions (e.g. `centos:7` or `centos:8`)
ARG CENTOS_BASE=centos:7

# Intermediate image to use as Opam-enabled distribution (e.g. `opam-alpine` or
# `opam-debian-based`).
ARG OPAM_BASE=opam-centos-based

FROM debian:12-slim AS downloader

# Add user with password-less sudo
ARG user=main
RUN useradd --create-home "$user" \
    && apt-get update \
    && apt-get install -y sudo \
    && apt-get clean \
    && echo "$user" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$user" \
    && chmod 0440 "/etc/sudoers.d/$user"
ENV PATH=/home/$user/.local/bin:$PATH
USER "$user"

# Install packages
USER root
RUN apt-get update \
    && apt-get install -y \
        unzip \
        wget \
    && apt-get clean
USER "$user"

# Add script for downloading files
COPY --chown="$user:$user" ci/static-dl /usr/local/bin/static-dl
RUN chmod +x /usr/local/bin/static-dl

RUN mkdir "/home/$user/workdir"
WORKDIR "/home/$user/workdir"

FROM downloader AS files-opam

RUN static-dl \
    --url https://github.com/ocaml/opam/releases/download/2.2.0/opam-2.2.0-x86_64-linux \
    --hash cc8c6db2110ae4e287a82fa7fa7d9c26045633107fac26a83894a5db2379a316 \
    --out opam
RUN chmod +x opam

FROM $DEBIAN_BASE AS opam-debian-based

# Add user with password-less sudo
ARG user=main
RUN useradd --create-home "$user" \
    && apt-get update \
    && apt-get install -y sudo \
    && apt-get clean \
    && echo "$user" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$user" \
    && chmod 0440 "/etc/sudoers.d/$user"
ENV PATH=/home/$user/.local/bin:$PATH
USER "$user"

# Install packages
USER root
RUN apt-get update \
    && apt-get install -y \
        bzip2 \
        gcc \
        git \
        make \
        patch \
        rsync \
        unzip \
        wget \
    && apt-get clean
USER "$user"

# Set up the OCaml environment
ARG OCAML_VERSION
COPY --from=files-opam /home/$user/workdir/opam /usr/local/bin/opam
RUN opam init --yes --compiler "$OCAML_VERSION" --disable-sandboxing

RUN mkdir "/home/$user/workdir"
WORKDIR "/home/$user/workdir"

FROM $CENTOS_BASE AS opam-centos-based

# Fix repository URLs (because CentOS 7 is deprecated)
RUN . /etc/os-release \
    && if [ "$ID" = "centos" ] && ([ "$VERSION_ID" = "7" ] || [ "$VERSION_ID" = "8" ]); then \
        sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/*.repo; \
        sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo; \
        sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo; \
    fi

# Add user with password-less sudo
ARG user=main
RUN useradd --create-home "$user" \
    && yum install -y sudo \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && echo "$user" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$user" \
    && chmod 0440 "/etc/sudoers.d/$user"
ENV PATH=/home/$user/.local/bin:$PATH
USER "$user"

# Install packages
USER root
RUN yum install -y \
        bzip2 \
        diffutils \
        gcc \
        git \
        make \
        patch \
        rsync \
        unzip \
        wget \
    && yum clean all \
    && rm -rf /var/cache/yum
USER "$user"

# Set up the OCaml environment
ARG OCAML_VERSION
COPY --from=files-opam /home/$user/workdir/opam /usr/local/bin/opam
RUN opam init --yes --compiler "$OCAML_VERSION" --disable-sandboxing

RUN mkdir "/home/$user/workdir"
WORKDIR "/home/$user/workdir"

FROM alpine:3.20.1 AS opam-alpine

# Add user with password-less sudo
ARG user=main
RUN addgroup "$user" \
    && adduser --disabled-password --home "/home/$user" --ingroup "$user" "$user" \
    && apk add --no-cache sudo \
    && echo "$user" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$user" \
    && chmod 0440 "/etc/sudoers.d/$user"
ENV PATH=/home/$user/.local/bin:$PATH
USER "$user"

# Install packages
USER root
RUN apk add --no-cache \
        bash \
        build-base \
        bzip2 \
        git \
        patch \
        pkgconfig \
        rsync \
        unzip \
        wget
USER "$user"

# Set up the OCaml environment
ARG OCAML_VERSION
COPY --from=files-opam /home/$user/workdir/opam /usr/local/bin/opam
RUN opam init --yes --compiler "$OCAML_VERSION" --disable-sandboxing

RUN mkdir "/home/$user/workdir"
WORKDIR "/home/$user/workdir"

FROM $OPAM_BASE AS main

COPY --chown="$user:$user" cs_api_client.opam cs_api_client.opam.locked .
RUN opam pin add --yes --no-action --kind path --locked . \
    && (. /etc/os-release && [ "$ID" = 'alpine' ] && sudo apk update || true) \
    && opam update \
    && opam install --confirm-level unsafe-yes \
        --deps-only --with-test --with-dev-setup --locked cs_api_client \
    && opam clean --all-switches --download-cache --logs --repo-cache \
    && (. /etc/os-release && [ "$ID" = 'alpine' ] && sudo apk cache clean || true)

COPY --chown="$user:$user" . .

ARG VERSION
RUN ./ci/subst.bash "$VERSION" \
    && opam install .

RUN mkdir /home/$user/build \
    && cp $(opam var bin)/cs-api /home/$user/build
