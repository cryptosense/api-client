FROM amazonlinux
RUN yum -y install \
    autoconf \
    bzip2 \
    gcc \
    git \
    glibc-devel \
    gmp-devel \
    libffi-devel \
    m4 \
    ncurses-devel \
    openssl \
    openssl-devel \
    pcre-devel \
    redhat-lsb-core \
    rsync \
    unzip \
    wget \
    which \
    zlib-devel
RUN curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh | sh
RUN useradd --create-home --shell /bin/bash opam
USER opam


ARG OCAML_VERSION
RUN opam init --disable-sandboxing -a -y --comp=$OCAML_VERSION --switch=$OCAML_VERSION
RUN mkdir /home/opam/api-client
WORKDIR /home/opam/api-client
COPY --chown=opam cs_api_client.opam .
RUN opam update \
    && opam pin add --no-action cs_api_client . -y \
    && opam depext cs_api_client \
    && opam install --deps-only cs_api_client -y
COPY --chown=opam . .
