Create a trace directory with multiple files in it:

  $ mkdir trace-dir
  $ touch trace-dir/trace-0 trace-dir/trace-1

Try to upload traces from that directory:

  $ cs-api upload-trace \
  >     --api-base-url localhost:1234 \
  >     --project-id 1 \
  >     --slot-name slot-0 \
  >     --trace-name trace-0 \
  >     --trace-file trace-dir
  INFO     Found trace file: trace-0
  INFO     Found trace file: trace-1
  ERROR    More than one file found in directory: trace-dir
  [1]
