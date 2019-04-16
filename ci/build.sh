#!/bin/bash
eval $(opam env)
dune subst
dune build cs_api_cli/cs_api_cli.exe
