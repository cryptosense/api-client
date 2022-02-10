ARG DISTRIB
FROM ocaml/opam:${DISTRIB} as code

# Set up user
ENV PATH "/home/opam/.local/bin:$PATH"

# Set up OCaml and opam
ARG OCAML_VERSION
RUN opam update \
    && opam switch $OCAML_VERSION
RUN opam repository set-url default https://opam.ocaml.org/

RUN mkdir /home/opam/workdir
WORKDIR /home/opam/workdir
COPY --chown=opam cs_api_client.opam .
RUN opam update \
    && opam pin add cs_api_client.dev . --no-action \
    && opam depext cs_api_client --yes --with-test \
    && opam install . --deps-only --with-test
COPY --chown=opam . .
ARG VERSION
RUN ./ci/subst.bash "$VERSION" \
    && opam exec -- dune build @all @runtest
