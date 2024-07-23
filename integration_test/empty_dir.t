Create a empty trace directory:

  $ mkdir trace-dir

Try to upload traces from that directory:

  $ cs-api upload-trace \
  >     --api-base-url localhost:1234 \
  >     --project-id 1 \
  >     --slot-name slot-0 \
  >     --trace-name trace-0 \
  >     --trace-file trace-dir
  Empty directory: trace-dir
  [1]
