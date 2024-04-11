# Cryptosense API Client

[![Build Status](https://travis-ci.com/cryptosense/api-client.svg?branch=master)](https://travis-ci.com/cryptosense/api-client)

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

Helper for opam install on linux:
`bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"`


### Setting up OPAM
```bash
opam init -y
eval $(opam env --switch=default)
```

### OPAM Dependencies
Install the following with `opam install ...`
 - ocurl
 - yojson
 - containers
 - base64
 - ppx_deriving
 - terminal_size
 - lwt
 - lwt_ppx
 - dune

## Build and Install 
After ensuring the dependencies have been fulfilled:
* Install the binary client from source: `dune build @install && dune install`
* Run tests: `dune runtest`

## Release

* Create a tag:
  * `git tag --message 'Version 1.2.3' 1.2.3`
  * `git push --tags`
* Create a release on GitHub for the new tag.
* Make sure the CHANGES.md file is up to date.
* Get the binaries from the [Actions tab][github_actions] on GitHub.
* Select the pipeline associated with your tag and go to the summary.
* Download the artifacts.
* Fix the Linux zip with `./ci/fix_zip.bash <path_to_zip>`
* Upload the binaries to the release.

[github_actions]: https://github.com/cryptosense/api-client/actions
