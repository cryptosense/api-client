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

  let create_trace =
    {|
      mutation CreateTrace($projectId: ID!, $name: String!, $key: String!, $size: Int!) {
        createTrace(
          input: {
            projectId: $projectId,
            name: $name,
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
  let data = json |> member "data" in
  let url = data |> member "url" |> to_string_option in
  let signature =
    data |> member "fields" |> member "x-amz-signature" |> to_string_option
  in
  let credential =
    data |> member "fields" |> member "x-amz-credential" |> to_string_option
  in
  let algorithm =
    data |> member "fields" |> member "x-amz-algorithm" |> to_string_option
  in
  let date =
    data |> member "fields" |> member "x-amz-date" |> to_string_option
  in
  let key = data |> member "fields" |> member "key" |> to_string_option in
  let policy = data |> member "fields" |> member "policy" |> to_string_option in
  let acl = data |> member "fields" |> member "acl" |> to_string_option in
  let success_action_status =
    data |> member "fields" |> member "success_action_status" |> to_int_option
  in
  url >>= fun url ->
  signature >>= fun signature ->
  key >>= fun key ->
  credential >>= fun credential ->
  date >>= fun date ->
  algorithm >>= fun algorithm ->
  policy >>= fun policy ->
  acl >>= fun acl ->
  success_action_status >|= fun success_action_status ->
  ( url
  , [ ("x-amz-signature", signature)
    ; ("x-amz-credential", credential)
    ; ("x-amz-algorithm", algorithm)
    ; ("x-amz-date", date)
    ; ("key", key)
    ; ("policy", policy)
    ; ("acl", acl)
    ; ("success_action_status", string_of_int success_action_status) ] )

let parse_s3_response ~body =
  let key_extractor = Str.regexp "<Key>\\([^<>]*\\)</Key>" in
  let _ = Str.search_forward key_extractor body 0 in
  Str.matched_group 1 body

let build_s3_signed_post_request ~api =
  let {Api.endpoint; key} = api in
  { Api.Request.url = endpoint ^ "/api/v1/trace_s3_post"
  ; header = [("API-KEY", key)]
  ; method_ = Post
  ; data = Multipart [] }

let build_file_upload_request ~s3_url ~s3_signature ~(file : Api.File.t) =
  let direct_fields =
    Api.Data.multipart_from_assoc
      (s3_signature
      @ [ ("Content-Type", "")
        ; ("x-amz-meta-filename", Filename.basename file.path) ])
  in
  { Api.Request.url = s3_url
  ; header = []
  ; method_ = Post
  ; data = Multipart (direct_fields @ [{name = "file"; content = File file}]) }

let build_trace_import_request ~api ~project_id ~s3_key ~trace_name ~file =
  let {Api.endpoint; key} = api in
  let {Api.File.size; _} = file in
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
                   [ ( "projectId"
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
