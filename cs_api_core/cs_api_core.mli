val parse_s3_signature_request :
  body:string -> (string * Api.S3Signature.t) option
(** Response parsing functions **)

val parse_s3_response : body:string -> string

val build_s3_signed_post_request : api:Api.t -> Api.Request.t
(** Request building functions **)

val build_file_upload_request :
     s3_url:string
  -> s3_signature:Api.S3Signature.t
  -> file:Api.File.t
  -> Api.Request.t

val build_trace_import_request :
     api:Api.t
  -> project_id:string
  -> s3_key:string
  -> trace_name:string
  -> file:Api.File.t
  -> Api.Request.t
