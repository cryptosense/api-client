let test ~name ~body ~expected_errors =
  ( name
  , `Quick
  , fun () ->
      let json = Yojson.Safe.from_string body in
      let result = Cs_api_io.get_graphql_errors json in
      Alcotest.(check (list string)) name result expected_errors )

let body_ok = {|{"data":{"createTrace":null}}|}

let body_error =
  {|{ 
    "errors": [
      {  
        "message": "No project with this ID was found",
        "locations": [{"line":3,"column":9}],
        "path": ["createTrace"]
      }
    ],
    "data": {"createTrace":null}
  }|}

let body_no_error_message =
  {|{
    "errors": [
      {
        "locations": [{"line":3,"column":9}],
        "path": ["createTrace"]
      }
    ],
    "data": {"createTrace":null}
  }|}

let body_multiple_errors =
  {|{
    "errors": [
      {"message": "No project with this ID was found"},
      {"message": "No project with this name was found"}
    ],
    "data": {"createTrace":null}
  }|}

let tests =
  [ test ~name:"test_ok" ~body:body_ok ~expected_errors:[]
  ; test ~name:"test_error" ~body:body_error
      ~expected_errors:["No project with this ID was found"]
  ; test ~name:"test_no_error_message" ~body:body_no_error_message
      ~expected_errors:["Unexpected response from the server"]
  ; test ~name:"test_multiple_errors" ~body:body_multiple_errors
      ~expected_errors:
        [ "No project with this ID was found"
        ; "No project with this name was found" ] ]
