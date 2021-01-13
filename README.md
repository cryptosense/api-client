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

If you are using self-signed certificates and want to upload anyway, use the
`--no-check-certificate` option.

#### HTTP Proxies

If you need to route your request through a proxy, set the `http_proxy` or `https_proxy`
environment variable to the URL of your proxy endpoint.

Note that, for now, the `--no-check-certificate` option has no effect on the checking of
the proxy certificate: it is always checked.

For more advanced configuration, please refer to the `curl` documentation.

## Development

* Install the binary client from source: `dune build @install && dune install`
* Run tests: `dune runtest`
