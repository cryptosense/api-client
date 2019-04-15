#!/bin/bash
eval $(opam env)
dune build cs_api_cli/cs_api_cli.exe
