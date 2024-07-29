# Cryptosense API Client

[![Build status][github_status_badge]][github_actions_main]

## Usage

The Cryptosense API Client depends on libcurl.

### Example

```bash
$ export CRYPTOSENSE_API_KEY=secret
$ ./cs-api upload-trace \
    --project-id 1 \
    --trace-name 'Test trace' \
    --trace-file test_trace.cst.gz
Request: POST https://analyzer.cryptosense.com/api/v1/trace_s3_post
Request: POST https://analyzer.cryptosense.com/api/v1/trace_s3_post
Request: POST https://analyzer.cryptosense.com/storage-traces
[=====================================================================================] 100.00%
Request: POST https://analyzer.cryptosense.com/api/v1/projects/1/traces
Trace imported
```

For more information about the CLI parameters, run: `cs-api --help`.

### FAQ

#### How to find the ID of my project?

In the web interface, select your project by clicking it and copy the number after
`/projects/` in the URL.

#### How to upload to a local instance of Cryptosense Analyzer?

Use the `--api-base-url` parameter to point the CLI at your local instance.

If you are using self-signed certificates or a custom CA, you can provide a custom CA file
with the `--ca-file path/to/cabundle.pem` option.

#### HTTP Proxies

If you need to route your request through a proxy, set the `http_proxy` or `https_proxy`
environment variable to the URL of your proxy endpoint.

Note that, for now, the `--no-check-certificate` option has no effect on the checking of
the proxy certificate: it is always checked.

For more advanced configuration, please refer to the `curl` documentation.

## Development

Make sure you are using Opam 2.2 or later. You will need basic
tools like:

- make
- clang
- patch
- curl

### Installing OCaml dependencies

```bash
opam switch create --no-action . 4.14.2
opam install --deps-only --with-test --with-dev-setup --working-dir .
eval $(opam env)  # This is for Linux (use the appropriate alternative on Windows).
```

### Installing Python dependencies

For end-to-end tests, we have Python dependencies managed by Poetry:

```bash
# Create a virtual environment (unless you'd like Poetry to manage it)
poetry install
```

For later steps, ensure the virtual environment is activated.

## Building

To build the executable, run:

```bash
dune build @install && dune install`
```

## Quality

### OCaml code

```bash
dune build @check @runtest
```

### Formatting

```bash
make format
```

### End-to-end tests

End-to-end tests are run with the Python test suite and should be checked on both Linux
and Windows.

Most of the tests require at least one running instance of the AQtive Guard API server.
Each instance is defined as an server in a TOML file. Tests for which pytest can't find a
suitable environment will be skipped.

Usage:

```bash
pytest \
    --executable=/path/to/cs-api \
    --server=/path/to/dev.toml \
    --server=/path/to/other_env.toml
```

Those tests can run either Linux and Windows. They can be run in parallel (e.g. `-n 4`).

Sample TOML file:

```toml
api_url = "https://localhost:8443"
api_key = "<secret-api-key>"
trusted_cert = false
ca_path = "/path/to/self-signed-cert.pem"
profile_id = 1
project_id = 3
slot_name = "cs-api-test"
```

## Updating dependencies

- Modify `cs_api.opam` and update your packages.
- Update the lock files:
  - On Linux: Run `opam lock .`.
  - On Windows: Run `opam lock --lock-suffix win.locked .`.

## Release

- Make sure your changes are in `main` and the `CHANGELOG.md` file is up to date.
- Create a tag for the updated `main`:
  - `git tag --message 'Version 1.2.3' 1.2.3`
  - `git push --tags --dry-run`
  - `git push --tags`
- Create a release on GitHub for the new tag.
- Get the binaries from the [Actions tab][github_actions] on GitHub.
- Test the binaries with the Python test suite on Windows and Linux.
- Select the pipeline associated with your tag and go to the summary.
- Download the artifacts.
- Fix the Linux zip with `./ci/fix_zip.bash <path_to_zip>`
- Upload the binaries to the release.

[github_actions]: https://github.com/cryptosense/api-client/actions
[github_actions_main]: https://github.com/cryptosense/api-client/actions?query=branch%3Amain
[github_status_badge]: https://github.com/cryptosense/api-client/actions/workflows/main.yml/badge.svg?branch=main
