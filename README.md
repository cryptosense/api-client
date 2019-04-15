# API Client

## Usage

cs-import - Import a trace into the Cryptosense analyzer

### Options

       -f TRACEFILE, --trace-file=TRACEFILE (required)
           Path to the file containing the trace

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -k API_KEY, --api-key=API_KEY (absent CRYPTOSENSE_API_KEY env)
           API key - can also be defined using the CRYPTOSENSE_API_KEY
           environment variable

       -n TRACENAME, --trace-name=TRACENAME (required)
           Name of the trace

       -p VAL, --project-id=VAL (required)
           ID of the project to which the trace should be added

       -u BASE_URL, --api-base-url=BASE_URL
       (absent=https://analyzer.cryptosense.com/api/v1)
           Base URL of the API. Should end with "/api/v1"

       --version
           Show version information.

## Install

Run `dune build @install && dune install` to install the binary client from the source

## Tests

Run `dune runtest`
