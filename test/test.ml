let method_to_string : Api.Method.t -> _ = function
  | Post -> "POST"
  | Get -> "GET"
  | Put -> "PUT"

let file_to_tuple : Api.File.t option -> _ = function
  | None -> None
  | Some {path; size} -> Some (path, size)

let test_request ~name ~expected ~actual =
  ( name
  , `Quick
  , fun () -> Alcotest.check (module Api.Request) name expected actual )

let request_builder_tests =
  let api = Api.make ~api_endpoint:"endpoint" ~api_key:"KEY" in
  [ test_request ~name:"S3 Signature request"
      ~expected:
        { Api.Request.url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc
                   [ ( "query"
                     , `String Cs_api_core.Graphql.generate_trace_upload_post )
                   ; ("variables", `Assoc []) ])) }
      ~actual:(Cs_api_core.build_s3_signed_post_request ~api)
  ; test_request ~name:"File upload request"
      ~expected:
        { url = "url"
        ; header = []
        ; method_ = Post
        ; data =
            Multipart
              (Api.Data.multipart_from_assoc
                 [ ("key", "abc")
                 ; ("signature", "cde")
                 ; ("Content-Type", "")
                 ; ("x-amz-meta-filename", "path") ]
              @ [ { name = "file"
                  ; content = File {path = "folder/path"; size = 10} } ]) }
      ~actual:
        (Cs_api_core.build_file_upload_request ~s3_url:"url"
           ~s3_method:Api.Method.Post
           ~s3_signature:[("key", "abc"); ("signature", "cde")]
           ~file:{path = "folder/path"; size = 10})
  ; test_request ~name:"File upload PUT"
      ~expected:
        { url = "url"
        ; header = []
        ; method_ = Put
        ; data = File {path = "folder/path"; size = 10} }
      ~actual:
        (Cs_api_core.build_file_upload_request ~s3_url:"url"
           ~s3_method:Api.Method.Put
           ~s3_signature:[("key", "abc"); ("signature", "cde")]
           ~file:{path = "folder/path"; size = 10})
  ; test_request ~name:"Trace import request without trace name"
      ~expected:
        { url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc
                   [ ("query", `String Cs_api_core.Graphql.create_trace)
                   ; ( "variables"
                     , `Assoc
                         [ ("slotName", `Null)
                         ; ( "projectId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id
                                  ~type_:"Project" ~id:9) )
                         ; ("name", `Null)
                         ; ("key", `String "abc")
                         ; ("size", `Int 10) ] ) ])) }
      ~actual:
        (Cs_api_core.build_trace_import_request ~api ~project_id:9
           ~slot_name:None ~s3_key:"abc" ~trace_name:None
           ~file:{path = "path"; size = 10})
  ; test_request ~name:"Trace import request without slot name"
      ~expected:
        { url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc
                   [ ("query", `String Cs_api_core.Graphql.create_trace)
                   ; ( "variables"
                     , `Assoc
                         [ ("slotName", `Null)
                         ; ( "projectId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id
                                  ~type_:"Project" ~id:9) )
                         ; ("name", `String "cde")
                         ; ("key", `String "abc")
                         ; ("size", `Int 10) ] ) ])) }
      ~actual:
        (Cs_api_core.build_trace_import_request ~api ~project_id:9
           ~slot_name:None ~s3_key:"abc" ~trace_name:(Some "cde")
           ~file:{path = "path"; size = 10})
  ; test_request ~name:"Trace import request with slot name"
      ~expected:
        { url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc
                   [ ("query", `String Cs_api_core.Graphql.create_trace)
                   ; ( "variables"
                     , `Assoc
                         [ ("slotName", `String "name")
                         ; ( "projectId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id
                                  ~type_:"Project" ~id:9) )
                         ; ("name", `String "cde")
                         ; ("key", `String "abc")
                         ; ("size", `Int 10) ] ) ])) }
      ~actual:
        (Cs_api_core.build_trace_import_request ~api ~project_id:9
           ~slot_name:(Some "name") ~s3_key:"abc" ~trace_name:(Some "cde")
           ~file:{path = "path"; size = 10})
  ; test_request ~name:"Trace analysis request"
      ~expected:
        { url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc
                   [ ("query", `String Cs_api_core.Graphql.analyze_trace)
                   ; ( "variables"
                     , `Assoc
                         [ ( "traceId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id ~type_:"Trace"
                                  ~id:9) )
                         ; ( "profileId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id
                                  ~type_:"Profile" ~id:2) ) ] ) ])) }
      ~actual:(Cs_api_core.build_analyze_request ~api ~trace_id:9 ~profile_id:2)
  ; test_request ~name:"List profiles request"
      ~expected:
        { Api.Request.url = "endpoint/api/v2"
        ; header = [("API-KEY", "KEY"); ("Content-Type", "application/json")]
        ; method_ = Post
        ; data =
            Raw
              (Yojson.Safe.to_string
                 (`Assoc [("query", `String Cs_api_core.Graphql.list_profiles)]))
        }
      ~actual:(Cs_api_core.build_list_profiles_request ~api) ]

let () =
  Alcotest.run "API Client"
    [ ("Request builders", request_builder_tests)
    ; ("Multipart writer", Test_writer.accumulator)
    ; ("Graphql errors parsing", Test_api_io.tests)
    ; ("S3 Key extraction", Test_key_extractor.tests) ]
