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

### System Requirements

Install the following with your system's package manager

- opam
- make
- clang
- patch
- curl
- libcurl-devel

### Setting up OPAM

```bash
opam switch create . 4.14.1  # for OCaml 4.14.1
eval $(opam env)
```

### OPAM Dependencies

Install dependencies with `opam pin add -k path .`

## Build and Install

After ensuring the dependencies have been fulfilled:

- Install the binary client from source: `dune build @install && dune install`
- Run tests: `dune runtest`

## Release

- Make sure your changes are in `main` and the `CHANGELOG.md` file is up to date.
- Create a tag for the updated `main`:
  - `git tag --message 'Version 1.2.3' 1.2.3`
  - `git push --tags --dry-run`
  - `git push --tags`
- Create a release on GitHub for the new tag.
- Get the binaries from the [Actions tab][github_actions] on GitHub.
- Select the pipeline associated with your tag and go to the summary.
- Download the artifacts.
- Fix the Linux zip with `./ci/fix_zip.bash <path_to_zip>`
- Upload the binaries to the release.

[github_actions]: https://github.com/cryptosense/api-client/actions
[github_actions_main]: https://github.com/cryptosense/api-client/actions?query=branch%3Amain
[github_status_badge]: https://github.com/cryptosense/api-client/actions/workflows/main.yml/badge.svg?branch=main
