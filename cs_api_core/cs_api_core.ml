(** Parsers **)
let parse_s3_signature_request ~body =
  let open CCOpt.Infix in
  let open Yojson.Basic.Util in
  let json = Yojson.Basic.from_string body in
  let data = json |> member "data" in
  let url = data |> member "url" |> to_string_option in
  let signature = data |> member "fields" |> member "signature" |> to_string_option in
  let key = data |> member "fields" |> member "key" |> to_string_option in
  let awsaccesskeyid = data |> member "fields" |> member "AWSAccessKeyId" |> to_string_option in
  let policy = data |> member "fields" |> member "policy" |> to_string_option in
  let acl = data |> member "fields" |> member "acl" |> to_string_option in
  let success_action_status = 
    data 
    |> member "fields"
    |> member "success_action_status"
    |> to_int_option 
  in
  url
  >>= fun url -> signature
  >>= fun signature -> key
  >>= fun key -> awsaccesskeyid
  >>= fun awsaccesskeyid -> policy
  >>= fun policy -> acl
  >>= fun acl -> success_action_status
  >|= fun success_action_status -> 
  ( url
  , [ ("signature", signature)
    ; ("key", key)
    ; ("AWSAccessKeyId", awsaccesskeyid)
    ; ("policy", policy)
    ; ("acl", acl)
    ; ("success_action_status", string_of_int success_action_status)
    ]
  )

let parse_s3_response ~body =
  let key_extractor = Str.regexp "<Key>\\([^<>]*\\)</Key>" in
  Str.search_forward key_extractor body 0;
  Str.matched_group 1 body

(** Request builders **)
let build_s3_signed_post_request ~api =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/trace_s3_post"
  ; form = []
  ; _method = Post
  ; header = [("API_KEY", key)]
  ; file = None
  }

let build_file_upload_request ~s3_url ~s3_signature ~file =
  {Api.Request.url = s3_url; form = s3_signature; _method = Post; header = []; file = Some file}

let build_trace_import_request ~api ~project_id ~s3_key ~trace_name ~file =
  let {Api.endpoint; key} = api in
  let {Api.Request.size; _} = file in
  { Api.Request.url = endpoint ^ "/projects/" ^ project_id ^ "/traces"
  ; form = [("key", s3_key); ("name", trace_name); ("size", string_of_int size)]
  ; _method = Post
  ; header = [("API_KEY", key)]
  ; file = None
  }
