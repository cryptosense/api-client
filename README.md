# Cryptosense API Client

[![Build Status](https://travis-ci.com/cryptosense/api-client.svg?branch=master)](https://travis-ci.com/cryptosense/api-client)

## Usage

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

#### How to upload to a local instance of Cryptosense Analyzer?

Use the `--api-base-url` parameter to point the CLI at your local instance.

If you are using self-signed certificates and want to upload anyway, use the
`--no-check-certificate` option.

## Development

* Install the binary client from source: `dune build @install && dune install`
* Run tests: `dune runtest`
