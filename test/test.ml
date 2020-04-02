let method_to_string m =
  match m with
  | Api.Request.Post -> "POST"
  | Get -> "GET"

let file_to_tuple f =
  match f with
  | None -> None
  | Some {Api.Request.path; size} -> Some (path, size)

let test_request ~name ~expected_url ~expected_method ~expected_headers ~expected_form ~expected_file {Api.Request.url; form; method_; header; file} =
  let open Alcotest in
  ( name
  , `Quick
  , fun () ->
    check string (name ^ " url") expected_url url;
    check string (name ^ " method") expected_method (method_to_string method_);
    check (list (pair string string)) (name ^ " headers") expected_headers header;
    check (list (pair string string)) (name ^ " form") expected_form form;
    check (option (pair string int)) (name ^ " file") expected_file (file_to_tuple file)
  )

let request_builder_tests =
  let api = Api.make ~api_endpoint:"endpoint" ~api_key:"KEY" in
  [ test_request
      ~name:"S3 Signature request"
      ~expected_url:"endpoint/api/v1/trace_s3_post"
      ~expected_method:"POST"
      ~expected_headers:[("API-KEY", "KEY")]
      ~expected_form:[]
      ~expected_file:None
      (Cs_api_core.build_s3_signed_post_request ~api)
  ; test_request
      ~name:"File upload request"
      ~expected_url:"url"
      ~expected_method:"POST"
      ~expected_headers:[]
      ~expected_form:[ ("key", "abc")
                     ; ("signature", "cde")
                     ; ("Content-Type", "")
                     ; ("x-amz-meta-filename", "path")
                     ]
      ~expected_file: (Some ("folder/path", 10))
      (Cs_api_core.build_file_upload_request
         ~s3_url:"url"
         ~s3_signature:[ ("key", "abc")
                       ; ("signature", "cde")
                       ]
         ~file:{path="folder/path"; size=10}
      )
  ; test_request
      ~name:"Trace import request"
      ~expected_url:"endpoint/api/v1/projects/9/traces"
      ~expected_method:"POST"
      ~expected_headers:[("API-KEY", "KEY")]
      ~expected_form:[ ("key", "abc")
                     ; ("name", "cde")
                     ; ("size", "10")
                     ]
      ~expected_file:None
      (Cs_api_core.build_trace_import_request
         ~api
         ~project_id:"9"
         ~s3_key:"abc"
         ~trace_name:"cde"
         ~file:{path="path"; size=10}
      )
  ]

let () =
  Alcotest.run
    "API Client"
    [ ("Request builders", request_builder_tests)
    ; ("Multipart writer", Test_writer.accumulator)
    ]
