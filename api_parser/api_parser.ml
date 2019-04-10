(** Helpers to chain options properly **)
let ( >>>= ) (s : 'a option) (f : 'a -> 'b option) : 'b option =
  match s with
  | None ->
    None
  | Some v ->
    f v

let return (v : 'a) : 'a option = Some v

(** Basic types **)
type api =
    { endpoint : string
    ; key : string
    }

type verb =
  | Get
  | Post

type request =
  { url : string
  ; form : (string * string) list
  ; verb : verb
  ; header : (string * string) list
  ; file : string option }

type s3_signature = (string * string) list

(** Constructors **)
let declare_api api_enpoint api_key =
    { endpoint = api_enpoint
    ; key = api_key
    }

(** Parsers **)
let parse_s3_signature_request body =
  let json = Yojson.Basic.from_string body in
  let open Yojson.Basic.Util in
  let data = json |> member "data" in
  let url = data |> member "url" |> to_string_option in
  let signature = data |> member "fields" |> member "signature" |> to_string_option in
  let key = data |> member "fields" |> member "key" |> to_string_option in
  let awsaccesskeyid = data |> member "fields" |> member "AWSAccessKeyId" |> to_string_option in
  let policy = data |> member "fields" |> member "policy" |> to_string_option in
  let acl = data |> member "fields" |> member "acl" |> to_string_option in
  let success_action_status = data |> member "fields" |> member "success_action_status" |> to_int_option in
  url
  >>>= fun url ->
  signature
  >>>= fun signature ->
  key
  >>>= fun key ->
  awsaccesskeyid
  >>>= fun awsaccesskeyid ->
  policy
  >>>= fun policy ->
  acl
  >>>= fun acl ->
  success_action_status
  >>>= fun success_action_status ->
  return
    ( url
    , [ ("signature", signature)
      ; ("key", key)
      ; ("AWSAccessKeyId", awsaccesskeyid)
      ; ("policy", policy)
      ; ("acl", acl)
      ; ("success_action_status", string_of_int success_action_status) ] )

let parse_s3_response body =
    let key_extractor = Str.regexp "<Key>\\([^<>]*\\)</Key>" in
    let _ = Str.search_forward key_extractor body 0; in
    Str.matched_group 1 body

(** Request builders **)
let build_s3_signed_post_request api =
  { url = api.endpoint ^ "/trace_s3_post"
  ; form = []
  ; verb = Post
  ; header = [("API_KEY", api.key)]
  ; file = None }

let build_file_upload_request url s3_signature file_path =
    {url; form = s3_signature; verb = Post; header = []; file = Some file_path}

let build_trace_import_request api project_id key trace_name file_size =
    { url = api.endpoint ^ "/projects/" ^ project_id ^ "/traces"
    ; form = [("key", key); ("name", trace_name); ("size", string_of_int file_size)]
    ; verb = Post
    ; header = [("API_KEY", api.key)]
    ; file = None }
