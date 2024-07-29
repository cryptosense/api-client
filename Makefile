python_src := test_end_to_end

.PHONY: help
help:
	# Taken from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: check-format-ocaml
check-format-ocaml:  ## Check OCaml formatting.
	dune build @fmt

.PHONY: check-format-python
check-format-python:  ## Check Python formatting.
	ruff check --select I --diff ${python_src}
	ruff format --check --diff ${python_src}

.PHONY: check-lint-python
check-lint-python:  ## Check Python code quality.
	ruff check ${python_src}
	dmypy run -- ${python_src}

.PHONY: format-ocaml
format-ocaml:  ## Format OCaml code.
	dune build @fmt --auto-promote

.PHONY: format-python
format-python:  ## Format Pyton code.
	ruff check --select I --fix ${python_src}
	ruff format ${python_src}

.PHONY: check-format
check-format: check-format-ocaml check-format-python  ## Check formatting.

.PHONY: check-lint
check-lint: check-lint-python  ## Check code quality.

.PHONY: check
check: check-lint check-format  ## Check everything.

.PHONY: format
format: format-ocaml format-python  ## Check everything.
