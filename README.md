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

* Install the binary client from source: `dune build @install && dune install`
* Run tests: `dune runtest`

## Release

* Create a tag:
  * `git tag --message 'Version 1.2.3' 1.2.3`
  * `git push --tags`
* Get the binaries from the ["Actions" tab] on GitHub
* Select the pipeline associated with your tag and go to the summary
* Download the binaries
* Create a release on GitHub for the new tag.
* Upload the binaries to the release
* Make sure the CHANGES.md file is up to date

["Actions" Tab]: https://github.com/cryptosense/api-client/actions
