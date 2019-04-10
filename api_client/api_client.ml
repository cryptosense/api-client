let main file_path trace_name project_id api_endpoint api_key =
  let open Lwt_result.Infix in
  let api = Api_parser.declare_api api_endpoint api_key in
  let s3_signed_post_request = Api_parser.build_s3_signed_post_request api in
  s3_signed_post_request
  |> Api_caller.send_request
  >>= Api_caller.get_response
  >>= (fun body ->
        match Api_parser.parse_s3_signature_request body with
        | None ->
          Lwt.return (Error "Failed to parse S3 signature request response")
        | Some (url, s3_signature) ->
          Lwt.return (Ok (Api_parser.build_file_upload_request url s3_signature file_path)) )
  >>= Api_caller.send_request
  >>= Api_caller.get_response
  >>= (fun (body) ->
        let key = Api_parser.parse_s3_response body in
        let file_stats = Lwt_main.run (Lwt_unix.stat file_path) in
        let file_size = file_stats.st_size in
        let import_request = Api_parser.build_trace_import_request api project_id key trace_name file_size in
        Lwt.return (Ok import_request)
  )
  >>= Api_caller.send_request
  >>= Api_caller.get_response
  |> Lwt_main.run


let info =
    let doc = "Import a trace into the Cryptosense analyzer" in
    Cmdliner.Term.info "cs-import" ~version:"0.1.0" ~doc ~exits:Cmdliner.Term.default_exits

let trace_file =
    let doc = "Path to the file containing the trace" in
    Cmdliner.Arg.(required & pos 0 (some string) None & info [] ~docv:"TRACEFILE" ~doc)

let trace_name =
    let doc = "Name of the trace" in
    Cmdliner.Arg.(required & pos 1 (some string) None & info [] ~docv:"TRACENAME" ~doc)

let project_id =
    let doc = "ID of the project to which the trace should be added" in
    Cmdliner.Arg.(value & opt int 1 & info ["p"; "project-id"] ~docv:"PROJECT_ID" ~doc)

let api_endpoint =
    let doc = "Endpoint of the API. Should end with \"/api/v1\"" in
    Cmdliner.Arg.(value & opt string "https://analyzer.cryptosense.com/api/v1" & info ["u"; "url"] ~docv:"URL" ~doc)

let api_key =
    let doc = "API key" in
    let env = Cmdliner.Arg.env_var "CRYPTOSENSE_API_KEY" ~doc in
    let doc = "API key - can also be defined using the CRYPTOSENSE_API_KEY environment variable" in
    Cmdliner.Arg.(value & opt string "" & info ["k"; "api-key"] ~env ~docv:"API_KEY" ~doc)

let main_t trace_file trace_name project_id api_endpoint api_key =
    match main trace_file trace_name (string_of_int project_id) api_endpoint api_key with
    | Ok _ ->
      print_endline "Trace successfully imported"
    | Error s ->
      print_endline s

let import_t =
    Cmdliner.Term.(const main_t $ trace_file $ trace_name $ project_id $ api_endpoint $ api_key)

let () =
    Cmdliner.Term.exit @@ Cmdliner.Term.eval (import_t, info)
