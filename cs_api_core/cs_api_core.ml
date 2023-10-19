module Graphql = struct
  let to_global_id ~type_ ~id =
    Printf.sprintf "%s:%d" type_ id |> Base64.encode |> Result.get_ok

  let of_global_id ~type_ global_id =
    global_id
    |> Base64.decode
    |> Result.get_ok
    |> CCString.chop_prefix ~pre:(Printf.sprintf "%s:" type_)
    |> CCOption.get_exn_or
         (Printf.sprintf "Invalid global ID prefix for type %s" type_)
    |> int_of_string

  let generate_trace_upload_post =
    {|
      mutation GenerateTraceUploadPost {
        generateTraceUploadPost(input: {}) {
          url
          formData
          method
        }
      }
    |}

  let create_trace =
    {|
      mutation CreateTrace($projectId: ID!, $name: String!, $slotName: String, $key: String!, $size: BigInt!) {
        createTrace(
          input: {
            projectId: $projectId,
            name: $name,
            defaultSlotName: $slotName,
            key: $key,
            size: $size
          }
        ) {
          trace {
            id
          }
        }
      }
    |}

  let analyze_trace =
    {|
      mutation AnalyzeTrace($traceId: ID!, $profileId: ID!) {
        analyze(
          input: {
            traceId: $traceId
            profileId: $profileId,
          }
        ) {
          report {
            name
            id
          }
        }
      }
    |}

  let list_profiles =
    {|
      query ListProfiles {
        viewer {
          organization {
            profiles {
              edges {
                node {
                  id
                  name
                  type
                }
              }
            }
          }
        }
      }
    |}

  let search_project_by_name =
    {|
      query SearchProject($name: String!) {
        viewer {
          project(name: $name) {
            id
            name
          }
        }
      }
    |}
end

let build_list_profiles_request ~api =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/api/v2"
  ; header = [("API-KEY", key); ("Content-Type", "application/json")]
  ; method_ = Post
  ; data =
      Raw
        (Yojson.Safe.to_string
           (`Assoc [("query", `String Graphql.list_profiles)])) }

let build_search_project_by_name_request ~api ~name =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/api/v2"
  ; header = [("API-KEY", key); ("Content-Type", "application/json")]
  ; method_ = Post
  ; data =
      Raw
        (Yojson.Safe.to_string
           (`Assoc
             [ ("query", `String Graphql.search_project_by_name)
             ; ("variables", `Assoc [("name", `String name)]) ])) }

let parse_list_profiles_response ~body =
  let open Yojson.Basic.Util in
  let json = Yojson.Basic.from_string body in
  json
  |> member "data"
  |> member "viewer"
  |> member "organization"
  |> member "profiles"
  |> member "edges"
  |> to_list
  |> CCList.map (fun edge ->
         let node = edge |> member "node" in
         ( node |> member "name" |> to_string
         , node
           |> member "id"
           |> to_string
           |> Graphql.of_global_id ~type_:"Profile"
         , node |> member "type" |> to_string ))

let parse_search_project_by_name_response ~body =
  let open Yojson.Basic.Util in
  let json = Yojson.Basic.from_string body in
  json |> member "data" |> member "viewer" |> member "project" |> fun project ->
  match project with
  | `Null -> None
  | _ ->
    Some
      (member "id" project |> to_string |> Graphql.of_global_id ~type_:"Project")

let parse_s3_signature_request ~body =
  let open CCOption.Infix in
  let open Yojson.Basic.Util in
  let json = Yojson.Basic.from_string body in
  let data = json |> member "data" |> member "generateTraceUploadPost" in
  let url = data |> member "url" |> to_string_option in
  let method_ = data |> member "method" |> to_string_option in
  let formData =
    match data |> member "formData" with
    | `String str -> Yojson.Basic.from_string str
    | _ -> `Null
  in
  let signature = formData |> member "x-amz-signature" |> to_string_option in
  let credential = formData |> member "x-amz-credential" |> to_string_option in
  let algorithm = formData |> member "x-amz-algorithm" |> to_string_option in
  let date = formData |> member "x-amz-date" |> to_string_option in
  let key = formData |> member "key" |> to_string_option in
  let policy = formData |> member "policy" |> to_string_option in
  let acl = formData |> member "acl" |> to_string_option in
  let success_action_status =
    formData |> member "success_action_status" |> to_int_option
  in
  url >>= fun url ->
  method_ >>= fun method_ ->
  if String.equal method_ "POST" then
    signature >>= fun signature ->
    key >>= fun key ->
    credential >>= fun credential ->
    date >>= fun date ->
    algorithm >>= fun algorithm ->
    policy >>= fun policy ->
    acl >>= fun acl ->
    success_action_status >|= fun success_action_status ->
    ( url
    , Api.Method.Post
    , [ ("x-amz-signature", signature)
      ; ("x-amz-credential", credential)
      ; ("x-amz-algorithm", algorithm)
      ; ("x-amz-date", date)
      ; ("key", key)
      ; ("policy", policy)
      ; ("acl", acl)
      ; ("success_action_status", string_of_int success_action_status) ] )
  else if String.equal method_ "PUT" then
    Some (url, Api.Method.Put, [])
  else
    raise (Invalid_argument ("Unknown method: " ^ method_))

let parse_s3_response ~body =
  try
    let key_extractor = Str.regexp "<Key>\\([^<>]*\\)</Key>" in
    let _ = Str.search_forward key_extractor body 0 in
    Ok (Str.matched_group 1 body)
  with
  | Not_found -> Error "Key could not be extracted from S3 response."

let parse_s3_url url =
  try
    let key_extractor = Str.regexp "/uploads/\\([a-z0-9]+\\)" in
    let _ = Str.search_forward key_extractor url 0 in
    Ok ("uploads/" ^ Str.matched_group 1 url)
  with
  | Not_found -> Error "Key could not be extracted from S3 URL."

let build_s3_signed_post_request ~api =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/api/v2"
  ; header = [("API-KEY", key); ("Content-Type", "application/json")]
  ; method_ = Post
  ; data =
      Raw
        (Yojson.Safe.to_string
           (`Assoc
             [ ("query", `String Graphql.generate_trace_upload_post)
             ; ("variables", `Assoc []) ])) }

let build_file_upload_request
    ~s3_url
    ~s3_method
    ~s3_signature
    ~(file : Api.File.t) =
  let direct_fields =
    Api.Data.multipart_from_assoc
      (s3_signature
      @ [ ("Content-Type", "")
        ; ("x-amz-meta-filename", Filename.basename file.path) ])
  in
  match s3_method with
  | Api.Method.Post ->
    { Api.Request.url = s3_url
    ; header = []
    ; method_ = Post
    ; data = Multipart (direct_fields @ [{name = "file"; content = File file}])
    }
  | Put ->
    {Api.Request.url = s3_url; header = []; method_ = Put; data = File file}
  | Get -> raise (Invalid_argument "Unsupported method: GET")

let build_trace_import_request
    ~api
    ~project_id
    ~slot_name
    ~s3_key
    ~trace_name
    ~file =
  let {Api.endpoint; key} = api in
  let {Api.File.size; _} = file in
  let slot_name_var =
    match slot_name with
    | Some name -> `String name
    | None -> `Null
  in
  { Api.Request.url = endpoint ^ "/api/v2"
  ; header = [("API-KEY", key); ("Content-Type", "application/json")]
  ; method_ = Post
  ; data =
      Raw
        (Yojson.Safe.to_string
           (`Assoc
             [ ("query", `String Graphql.create_trace)
             ; ( "variables"
               , `Assoc
                   [ ("slotName", slot_name_var)
                   ; ( "projectId"
                     , `String
                         (Graphql.to_global_id ~type_:"Project" ~id:project_id)
                     )
                   ; ("name", `String trace_name)
                   ; ("key", `String s3_key)
                   ; ("size", `Int size) ] ) ])) }

let build_analyze_request ~api ~trace_id ~profile_id =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/api/v2"
  ; header = [("API-KEY", key); ("Content-Type", "application/json")]
  ; method_ = Post
  ; data =
      Raw
        (Yojson.Safe.to_string
           (`Assoc
             [ ("query", `String Graphql.analyze_trace)
             ; ( "variables"
               , `Assoc
                   [ ( "traceId"
                     , `String
                         (Graphql.to_global_id ~type_:"Trace" ~id:trace_id) )
                   ; ( "profileId"
                     , `String
                         (Graphql.to_global_id ~type_:"Profile" ~id:profile_id)
                     ) ] ) ])) }

let get_id_from_trace_import_response_body ~body =
  let open Yojson.Basic.Util in
  Yojson.Basic.from_string body
  |> member "data"
  |> member "createTrace"
  |> member "trace"
  |> member "id"
  |> to_string
  |> Graphql.of_global_id ~type_:"Trace"

let get_info_from_analyze_response_body ~body =
  let open Yojson.Basic.Util in
  Yojson.Basic.from_string body
  |> member "data"
  |> member "analyze"
  |> member "report"
  |> fun json ->
  let name = member "name" json |> to_string in
  let id =
    member "id" json |> to_string |> Graphql.of_global_id ~type_:"Report"
  in
  (name, id)
