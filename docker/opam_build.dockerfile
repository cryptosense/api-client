ARG DISTRIB
FROM ocaml/opam2:${DISTRIB}
ARG OCAML_VERSION
RUN opam switch $OCAML_VERSION || opam switch create $OCAML_VERSION
RUN opam repository set-url default https://opam.ocaml.org/
RUN mkdir /home/opam/api-client
WORKDIR /home/opam/api-client
COPY --chown=opam cs_api_client.opam .
RUN opam update \
    && opam pin add --no-action cs_api_client . -y \
    && opam depext cs_api_client \
    && opam install --deps-only cs_api_client -y
COPY --chown=opam . .
