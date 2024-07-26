Create a trace directory with no permissions:

  $ mkdir trace-dir
  $ chmod 000 trace-dir

Try to upload traces from that directory:

  $ cs-api upload-trace \
  >     --api-base-url localhost:1234 \
  >     --project-id 1 \
  >     --slot-name slot-0 \
  >     --trace-name trace-0 \
  >     --trace-file trace-dir
  ERROR    Permission denied for path: trace-dir
  [1]

Restore the permissions on the directory so that Dune can clean up the test directory:

  $ chmod 755 trace-dir
