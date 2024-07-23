Create a trace directory with no permissions:

  $ touch trace-file

Try to upload traces from that directory:

  $ cs-api upload-trace \
  >     --api-base-url localhost:1 \
  >     --project-id 1 \
  >     --slot-name slot-0 \
  >     --trace-name trace-0 \
  >     --trace-file trace-file \
  > | sed 's/\(HTTP error (CURLE_COULDNT_CONNECT):\).*/\1 <redacted>/'  # Redact the platform-dependent part of the message.
  HTTP error (CURLE_COULDNT_CONNECT): <redacted>
