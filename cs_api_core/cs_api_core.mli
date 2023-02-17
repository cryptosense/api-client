module Graphql : sig
  val to_global_id : type_:string -> id:int -> string

  val generate_trace_upload_post : string

  val create_trace : string

  val analyze_trace : string

  val list_profiles : string
end

val parse_s3_signature_request :
  body:string -> (string * Api.S3Signature.t) option
(** Response parsing functions **)

val parse_s3_response : body:string -> string

val build_s3_signed_post_request : api:Api.t -> Api.Request.t
(** Request building functions **)

val build_list_profiles_request : api:Api.t -> Api.Request.t

val build_search_project_by_name_request :
  api:Api.t -> name:string -> Api.Request.t

val parse_list_profiles_response : body:string -> (string * int * string) list

val parse_search_project_by_name_response : body:string -> int option

val build_file_upload_request :
     s3_url:string
  -> s3_signature:Api.S3Signature.t
  -> file:Api.File.t
  -> Api.Request.t

val build_trace_import_request :
     api:Api.t
  -> project_id:int
  -> slot_name:string option
  -> s3_key:string
  -> trace_name:string
  -> file:Api.File.t
  -> Api.Request.t

val build_analyze_request :
  api:Api.t -> trace_id:int -> profile_id:int -> Api.Request.t

val get_id_from_trace_import_response_body : body:string -> int

val get_info_from_analyze_response_body : body:string -> string * int
