let method_to_string : Api.Method.t -> _ = function
  | Post -> "POST"
  | Get -> "GET"

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
        { Api.Request.url = "endpoint/api/v1/trace_s3_post"
        ; header = [("API-KEY", "KEY")]
        ; method_ = Post
        ; data = Multipart [] }
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
           ~s3_signature:[("key", "abc"); ("signature", "cde")]
           ~file:{path = "folder/path"; size = 10})
  ; test_request ~name:"Trace import request"
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
                         [ ( "projectId"
                           , `String
                               (Cs_api_core.Graphql.to_global_id
                                  ~type_:"Project" ~id:9) )
                         ; ("name", `String "cde")
                         ; ("key", `String "abc")
                         ; ("size", `Int 10) ] ) ])) }
      ~actual:
        (Cs_api_core.build_trace_import_request ~api ~project_id:9 ~s3_key:"abc"
           ~trace_name:"cde" ~file:{path = "path"; size = 10}) ]

let () =
  Alcotest.run "API Client"
    [ ("Request builders", request_builder_tests)
    ; ("Multipart writer", Test_writer.accumulator) ]
