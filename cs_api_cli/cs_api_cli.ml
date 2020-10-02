let get_file path =
  Lwt.catch
    (fun () ->
      path
      |> Lwt_io.file_length
      |> Lwt.map Int64.to_int
      |> Lwt.map (fun s -> {Api.Request.path; size = s})
      |> Lwt_result.ok)
    (function
      | Unix.Unix_error (Unix.ENOENT, "stat", _) ->
        Lwt_result.fail ("File " ^ path ^ " not found")
      | Unix.Unix_error (Unix.EACCES, _, _) ->
        Lwt_result.fail ("Permission denied on " ^ path)
      | Unix.Unix_error (Unix.EBUSY, _, _) ->
        Lwt_result.fail ("File " ^ path ^ " was busy")
      | _ ->
        Lwt_result.fail ("Could not read file " ^ path ^ " for unknown reasons"))

let upload_trace
    ~trace_file
    ~trace_name
    ~project_id
    ~api_endpoint
    ~api_key
    ~no_check_certificate =
  let open Lwt.Infix in
  Conduit_lwt_unix.tls_library := OpenSSL;
  let verify = not no_check_certificate in
  let api = Api.make ~api_endpoint ~api_key in
  (let open Lwt_result.Infix in
  get_file trace_file >>= fun file ->
  Cs_api_core.build_s3_signed_post_request ~api
  |> Cs_api_io.send_request ~verify
  >>= Cs_api_io.get_response
  >>= (fun body ->
        match Cs_api_core.parse_s3_signature_request ~body with
        | None ->
          Lwt.return (Error "Failed to parse S3 signature request response")
        | Some (s3_url, s3_signature) ->
          Lwt.return
            (Ok
               (Cs_api_core.build_file_upload_request ~s3_url ~s3_signature
                  ~file)))
  >>= Cs_api_io.send_request ~verify
  >>= Cs_api_io.get_response
  >>= (fun body ->
        let s3_key = Cs_api_core.parse_s3_response ~body in
        let import_request =
          Cs_api_core.build_trace_import_request ~api ~project_id ~s3_key
            ~trace_name ~file
        in
        Lwt.return (Ok import_request))
  >>= Cs_api_io.send_request ~verify
  >>= Cs_api_io.get_response
  >|= fun _ -> Printf.printf "Trace uploaded\n")
  >|= function
  | Ok _ as ok -> ok
  | Error message ->
    Printf.printf "%s\n" message;
    Error ()

let trace_file =
  let doc = "Path to the file containing the trace" in
  Cmdliner.Arg.(
    required
    & opt (some non_dir_file) None
    & info ["f"; "trace-file"] ~docv:"TRACEFILE" ~doc)

let trace_name =
  let doc = "Name of the trace" in
  Cmdliner.Arg.(
    required
    & opt (some string) None
    & info ["n"; "trace-name"] ~docv:"TRACENAME" ~doc)

let project_id =
  let doc = "ID of the project to which the trace should be added" in
  Cmdliner.Arg.(required & opt (some int) None & info ["p"; "project-id"] ~doc)

let api_endpoint =
  let doc = "Base URL of the API server." in
  Cmdliner.Arg.(
    value
    & opt string "https://analyzer.cryptosense.com"
    & info ["u"; "api-base-url"] ~docv:"BASE_URL" ~doc)

let api_key =
  let doc = "API key" in
  let env = Cmdliner.Arg.env_var "CRYPTOSENSE_API_KEY" ~doc in
  let doc =
    "API key - can also be defined using the CRYPTOSENSE_API_KEY environment \
     variable"
  in
  Cmdliner.Arg.(
    value & opt string "" & info ["k"; "api-key"] ~env ~docv:"API_KEY" ~doc)

let no_check_certificate =
  let doc =
    "Don't check remote certificates.  This is useful for when the platform is \
     installed on-premises with self-signed certificates"
  in
  Cmdliner.Arg.(value & flag & info ~doc ["no-check-certificate"])

let upload_trace_main
    trace_file
    trace_name
    project_id
    api_endpoint
    api_key
    no_check_certificate =
  upload_trace ~trace_file ~trace_name ~project_id:(string_of_int project_id)
    ~api_endpoint ~api_key ~no_check_certificate
  |> Lwt_main.run

let upload_trace_term =
  Cmdliner.Term.(
    const upload_trace_main
    $ trace_file
    $ trace_name
    $ project_id
    $ api_endpoint
    $ api_key
    $ no_check_certificate)

let upload_trace_info =
  Cmdliner.Term.info "upload-trace"
    ~doc:"Upload a trace to the Cryptosense Analyzer platform"

let upload_trace_cmd = (upload_trace_term, upload_trace_info)

let default_term =
  Cmdliner.Term.(ret (const (`Error (true, "Missing command"))))

let default_info = Cmdliner.Term.info "cs-api" ~version:"%%VERSION_NUM%%"

let default_cmd = (default_term, default_info)

let () =
  Cmdliner.Term.eval_choice default_cmd [upload_trace_cmd] |> Cmdliner.Term.exit
