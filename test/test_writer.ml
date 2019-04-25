module TestInput = struct
  type t =
    | Form of (string * string)
    | File of (string * string)
end

let multipart_request_to_string mp =
  let body_result = 
    mp
    |> Multipart_form_writer.r_body
    |> Lwt_main.run in
  let header_result =
    mp
    |> Multipart_form_writer.r_headers
    |> Lwt_main.run in
  match (header_result, body_result) with
  | (Ok headers, Ok stream)
    ->
    ( headers
    , stream
      |> Lwt_stream.get_available
      |> String.concat ""
    )
  | (_, Error err)
  | (Error err, _)
    ->
    ([], err)

let separator = "---------------16456c9a1a" 

let add_test_element mp element =
  match element with
  | TestInput.Form (name, value) -> Multipart_form_writer.add_form_element ~name ~value mp
  | File (name, path) -> Multipart_form_writer.add_file_from_disk ~name ~path mp

let test ~name ~input ~expected_headers ~expected_body =
  ( name
  , `Quick
  , fun () ->
    let (headers, body) =
      input
      |> List.fold_left 
        add_test_element
        (Multipart_form_writer.init_with_separator separator)
      |> multipart_request_to_string
    in
    Alcotest.(check (list (pair string string))) (name ^ "_headers") expected_headers headers;
    Alcotest.(check string) (name ^ "_body") expected_body body
  )

let test_fail ~name ~input ~expected_error =
  ( name
  , `Quick
  , fun () ->
    let (_, error) = 
      input
      |> List.fold_left 
        add_test_element
        (Multipart_form_writer.init_with_separator separator)
      |> multipart_request_to_string
    in
    Alcotest.(check string) name expected_error error
  )

let accumulator =
  [ test
      ~name:"Empty"
      ~input:[]
      ~expected_headers:
        [ ("Content-Type", "multipart/form-data; boundary=" ^ separator)
        ; ("Content-Length", "33")
        ]
      ~expected_body:("\r\n--" ^ separator ^ "--\r\n")
  ; test
      ~name:"Simple form"
      ~input:[Form ("key", "value")]
      ~expected_headers:[("Content-Type", "multipart/form-data; boundary=" ^ separator);
                         ("Content-Length", "115")]
      ~expected_body:("--" ^ separator
                      ^ "\r\n"
                      ^ "Content-Disposition: form-data; name=\"key\""
                      ^ "\r\n" ^ "\r\n"
                      ^ "value" ^ "\r\n"
                      ^ "\r\n"
                      ^ "--" ^ separator ^ "--"
                      ^ "\r\n"
                     )
  ; test_fail
      ~name:"Missing file"
      ~input:[File ("missing_file", "/this/file/does/not/exist")]
      ~expected_error:"File /this/file/does/not/exist not found"
  ]
