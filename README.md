# Cryptosense API Client

[![Build Status](https://travis-ci.com/cryptosense/api-client.svg?branch=master)](https://travis-ci.com/cryptosense/api-client)

## Usage

Example:

```bash
> ./cs-api \
    --project-id 1 \
    --trace-name 'Test trace' \
    --trace-file test_trace.cst.gz \
    --no-check-certificate \
    --api-base-url https://cryptosense-analyzer.local
Request: POST https://cryptosense-analyzer.local/api/v1/trace_s3_post
Request: POST https://cryptosense-analyzer.local/api/v1/trace_s3_post
Request: POST https://cryptosense-analyzer.local/storage-traces
[=====================================================================================] 100.00%
Request: POST https://cryptosense-analyazer.local/api/v1/projects/1/traces
Trace imported
```

For more information about the CLI parameters, run: `cs-api --help`.

## Development

* Install the binary client from source: `dune build @install && dune install`
* Run tests: `dune runtest`
