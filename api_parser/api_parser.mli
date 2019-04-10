(** Types for requests **)
type api
type verb = 
    | Get 
    | Post
type request =
  { url : string
  ; form : (string * string) list
  ; verb : verb
  ; header : (string * string) list
  ; file : string option }

(** Constructors **)
val declare_api : string -> string -> api



(** Response parsing functions **)
type s3_signature 
val parse_s3_signature_request : string -> (string * s3_signature) option
val parse_s3_response : string -> string

(** Request building functions **)
val build_s3_signed_post_request : api -> request
val build_file_upload_request : string -> s3_signature -> string -> request
val build_trace_import_request : api -> string -> string -> string -> int -> request
