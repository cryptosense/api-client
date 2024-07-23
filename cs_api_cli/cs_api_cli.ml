module Errors = struct
  let does_not_exist path = Printf.sprintf "Path does not exist: %s" path
  let denied path = Printf.sprintf "Permission denied for path: %s" path
  let busy path = Printf.sprintf "Path busy: %s" path
  let empty_directory path = Printf.sprintf "Empty directory: %s" path

  let too_many_files path =
    Printf.sprintf "More than one file found in directory: %s" path

  let unknown ~path ~error =
    Printf.sprintf "I/O error for path (%s): %s" path (Printexc.to_string error)
end

module Read_dir = struct
  type t =
    | File of Api.File.t
    | Not_a_directory
    | Failure of string

  let from_file path =
    let open Lwt.Infix in
    let open Lwt.Syntax in
    try%lwt
      let contents =
        Lwt_unix.files_of_directory path
        |> Lwt_stream.filter (fun filename ->
               (not (String.equal filename "."))
               && not (String.equal filename ".."))
      in
      let* first_two =
        Lwt_stream.nget 2 contents >|= List.sort String.compare
      in
      List.iter
        (fun filename -> Printf.printf "Found trace file: %s\n" filename)
        first_two;
      match first_two with
      | [] -> Lwt.return (Failure (Errors.empty_directory path))
      | [filename] ->
        let file_path = Filename.concat path filename in
        let* size = Lwt_io.file_length file_path in
        Lwt.return (File {Api.File.path = file_path; size = Int64.to_int size})
      | _ -> Lwt.return (Failure (Errors.too_many_files path))
    with
    | Unix.Unix_error (ENOTDIR, "opendir", _) -> Lwt.return Not_a_directory
    | Unix.Unix_error (ENOENT, _, _) ->
      Lwt.return (Failure (Errors.does_not_exist path))
    | Unix.Unix_error (EACCES, _, _) ->
      Lwt.return (Failure (Errors.denied path))
    | Unix.Unix_error (EBUSY, _, _) -> Lwt.return (Failure (Errors.busy path))
    | Unix.Unix_error _ as error ->
      Lwt.return (Failure (Errors.unknown ~path ~error))
end

let get_normal_file path =
  try%lwt
    path
    |> Lwt_io.file_length
    |> Lwt.map Int64.to_int
    |> Lwt.map (fun s -> {Api.File.path; size = s})
    |> Lwt_result.ok
  with
  | Unix.Unix_error (ENOENT, "stat", _) ->
    Lwt_result.fail (Errors.does_not_exist path)
  | Unix.Unix_error (EACCES, _, _) -> Lwt_result.fail (Errors.denied path)
  | Unix.Unix_error (EBUSY, _, _) -> Lwt_result.fail (Errors.busy path)
  | Unix.Unix_error _ as error -> Lwt_result.fail (Errors.unknown ~path ~error)

let get_file path =
  (* Try to read the path as a directory file first, then as a normal file. *)
  match%lwt Read_dir.from_file path with
  | File file -> Lwt_result.return file
  | Not_a_directory -> get_normal_file path
  | Failure msg -> Lwt_result.fail msg

let resolve_project_name ~client ~api ~project_id ~project_name =
  (* The user can provide an ID or a name. If a name is provided, look for the
     corresponding ID. Otherwise, just return the given ID. *)
  let open Lwt_result.Infix in
  match (project_id, project_name) with
  | (None, None)
  | (Some _, Some _) ->
    Lwt_result.fail "Exactly one of project ID or name must be provided."
  | (Some id, None) -> Lwt_result.return id
  | (None, Some name) -> (
    Cs_api_core.build_search_project_by_name_request ~api ~name
    |> Cs_api_io.send_request ~client
    >>= Cs_api_io.get_response_graphql
    >>= fun body ->
    Cs_api_core.parse_search_project_by_name_response ~body |> function
    | None -> Lwt_result.fail (Printf.sprintf "Project name not found: %s" name)
    | Some id -> Lwt_result.return id)

let rec analyze_trace ~client ~trace_id ~api ~count profile_id =
  let open Lwt.Infix in
  (let open Lwt_result.Infix in
   Cs_api_core.build_analyze_request ~api ~trace_id ~profile_id
   |> Cs_api_io.send_request ~client
   >>= Cs_api_io.get_response_graphql)
  >>= function
  | Error "Not found" ->
    Printf.printf "Profile ID not found\n";
    Lwt.return 1
  | Error "This trace is still being processed" when count > 1 ->
    Unix.sleep 5;
    analyze_trace ~client ~trace_id ~api ~count:(count - 1) profile_id
  | Error message ->
    Printf.printf "%s\n" message;
    Lwt.return 1
  | Ok body ->
    let (name, id) = Cs_api_core.get_info_from_analyze_response_body ~body in
    Printf.printf "Report '%s' of ID %i is being generated\n" name id;
    Lwt.return 0

let upload_trace
    ~client
    ~trace_file
    ~trace_name
    ~project_id
    ~project_name
    ~slot_name
    ~analyze
    ~api =
  let open Lwt.Infix in
  (let open Lwt_result.Infix in
   get_file trace_file >>= fun file ->
   resolve_project_name ~client ~api ~project_id ~project_name
   >>= fun project_id ->
   Cs_api_core.build_s3_signed_post_request ~api
   |> Cs_api_io.send_request ~client
   >>= Cs_api_io.get_response_graphql
   >>= (fun body ->
         match Cs_api_core.parse_s3_signature_request ~body with
         | None ->
           Lwt.return (Error "Failed to parse S3 signature request response")
         | Some (s3_url, s3_method, s3_signature) ->
           Lwt.return
             (Ok
                ( s3_url
                , Cs_api_core.build_file_upload_request ~s3_url ~s3_method
                    ~s3_signature ~file )))
   >>= (fun (url, request) ->
         ( Cs_api_io.send_request ~client request >>= fun response ->
           Cs_api_io.get_response response )
         >>= fun body ->
         match Cs_api_core.parse_s3_response ~body with
         | Ok s3_key -> Lwt_result.return s3_key
         | Error _ -> Lwt.return (Cs_api_core.parse_s3_url url))
   >>= (fun s3_key ->
         let import_request =
           Cs_api_core.build_trace_import_request ~slot_name ~api ~project_id
             ~s3_key ~trace_name ~file
         in
         Lwt.return (Ok import_request))
   >>= Cs_api_io.send_request ~client
   >>= Cs_api_io.get_response_graphql)
  >>= function
  | Ok body ->
    let trace_id = Cs_api_core.get_id_from_trace_import_response_body ~body in
    Printf.printf "Trace %i uploaded\n%!" trace_id;
    analyze
    |> CCOption.map_or ~default:(Lwt.return 0)
         (Unix.sleep 5;
          analyze_trace ~client ~trace_id ~api ~count:12)
  | Error message ->
    Printf.printf "%s\n" message;
    Lwt.return 1

let list_profiles ~client ~api =
  let open Lwt.Infix in
  (let open Lwt_result.Infix in
   Cs_api_core.build_list_profiles_request ~api
   |> Cs_api_io.send_request ~client
   >>= Cs_api_io.get_response_graphql
   >|= fun body -> Cs_api_core.parse_list_profiles_response ~body)
  >|= function
  | Error message ->
    Printf.printf "%s\n" message;
    1
  | Ok profile_list ->
    CCList.iter
      (fun (name, id, _type) ->
        Printf.printf "Profile %s of ID %i used for %s traces\n" name id _type)
      profile_list;
    0

let trace_file =
  let doc =
    "Path to the trace file to upload, or directory containing the trace file. \
     If this is a directory, it must contain exactly one file."
  in
  Cmdliner.Arg.(
    required
    & opt (some file) None
    & info ["f"; "trace-file"] ~docv:"TRACEFILE" ~doc)

let trace_id =
  let doc = "ID of the trace to analyze" in
  Cmdliner.Arg.(required & opt (some int) None & info ["trace-id"] ~doc)

let trace_name =
  let doc = "Name of the trace" in
  Cmdliner.Arg.(
    required
    & opt (some string) None
    & info ["n"; "trace-name"] ~docv:"TRACENAME" ~doc)

let project_id =
  let doc =
    "ID of the project to which the trace should be added. Mutually exclusive \
     with --project-name."
  in
  Cmdliner.Arg.(value & opt (some int) None & info ["p"; "project-id"] ~doc)

let slot_name =
  let doc =
    "Name of the slot the trace should be added to. If no slot with this name \
     exist in the chosen project then one will be created."
  in
  Cmdliner.Arg.(value & opt (some string) None & info ["slot-name"] ~doc)

let project_name =
  let doc =
    "Name of the project to which the trace should be added. Mutually \
     exclusive with --project-id."
  in
  Cmdliner.Arg.(value & opt (some string) None & info ["project-name"] ~doc)

let profile_id =
  let doc =
    "ID of the profile you want to use to analyze the trace. You can use the \
     list-profiles command to get the IDs of the existing profiles."
  in
  Cmdliner.Arg.(required & opt (some int) None & info ["profile-id"] ~doc)

let analyze =
  let doc =
    "ID of the profile you want to use to analyze the trace. You can use the \
     list-profiles command to get the IDs of the existing profiles."
  in
  Cmdliner.Arg.(value & opt (some int) None & info ["analyze"] ~doc)

let api_endpoint =
  let doc = "Base URL of the API server." in
  Cmdliner.Arg.(
    value
    & opt string "https://analyzer.cryptosense.com"
    & info ["u"; "api-base-url"] ~docv:"BASE_URL" ~doc)

let api_key =
  let doc = "API key" in
  let env = Cmdliner.Cmd.Env.info "CRYPTOSENSE_API_KEY" ~doc in
  let doc =
    "API key - can also be defined using the CRYPTOSENSE_API_KEY environment \
     variable"
  in
  Cmdliner.Arg.(
    value & opt string "" & info ["k"; "api-key"] ~env ~docv:"API_KEY" ~doc)

let ca_file =
  let doc =
    "Path to a file containing PEM encoded certificates to be trusted, to \
     override the default CA file. This has no effect if certificate checking \
     is disabled (it is enabled by default)."
  in
  Cmdliner.Arg.(
    value & opt (some non_dir_file) None & info ["ca-file"] ~docv:"CA_FILE" ~doc)

let no_check_certificate =
  let doc =
    "Don't check remote certificates. This is useful for when the platform is \
     installed on-premises with self-signed certificates. For security, \
     certificate checking is enabled by default."
  in
  Cmdliner.Arg.(value & flag & info ~doc ["no-check-certificate"])

let run_command ~ca_file ~no_check_certificate ~api_endpoint ~api_key f =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let api = Api.make ~api_endpoint ~api_key in
  Fun.protect
    (fun () ->
      let config =
        {Cs_api_io.Config.verify = not no_check_certificate; ca_file}
      in
      Cs_api_io.with_client ~config ~f:(fun client ->
          f ~client ~api |> Lwt_main.run))
    ~finally:(fun () -> Curl.global_cleanup ())

let upload_trace_main
    trace_file
    trace_name
    project_id
    project_name
    slot_name
    analyze
    api_endpoint
    api_key
    ca_file
    no_check_certificate =
  upload_trace ~trace_file ~trace_name ~project_id ~project_name ~slot_name
    ~analyze
  |> run_command ~ca_file ~no_check_certificate ~api_endpoint ~api_key

let analyze_trace_main
    trace_id
    profile_id
    api_endpoint
    api_key
    ca_file
    no_check_certificate =
  analyze_trace ~trace_id ~count:1 profile_id
  |> run_command ~ca_file ~no_check_certificate ~api_key ~api_endpoint

let list_profiles_main api_endpoint api_key ca_file no_check_certificate =
  list_profiles
  |> run_command ~ca_file ~no_check_certificate ~api_key ~api_endpoint

let list_profiles_term =
  Cmdliner.Term.(
    const list_profiles_main
    $ api_endpoint
    $ api_key
    $ ca_file
    $ no_check_certificate)

let list_profiles_info =
  Cmdliner.Cmd.info "list-profiles"
    ~doc:"List the available profiles of the Cryptosense Analyzer platform"

let list_profiles_cmd = Cmdliner.Cmd.v list_profiles_info list_profiles_term

let analyze_term =
  Cmdliner.Term.(
    const analyze_trace_main
    $ trace_id
    $ profile_id
    $ api_endpoint
    $ api_key
    $ ca_file
    $ no_check_certificate)

let analyze_info =
  Cmdliner.Cmd.info "analyze" ~doc:"Analyze a trace to create a report"

let analyze_cmd = Cmdliner.Cmd.v analyze_info analyze_term

let upload_trace_term =
  Cmdliner.Term.(
    const upload_trace_main
    $ trace_file
    $ trace_name
    $ project_id
    $ project_name
    $ slot_name
    $ analyze
    $ api_endpoint
    $ api_key
    $ ca_file
    $ no_check_certificate)

let upload_trace_info =
  Cmdliner.Cmd.info "upload-trace"
    ~doc:"Upload a trace to the Cryptosense Analyzer platform"

let upload_trace_cmd = Cmdliner.Cmd.v upload_trace_info upload_trace_term

let default_term =
  Cmdliner.Term.(ret (const (`Error (true, "Missing command"))))

let default_info = Cmdliner.Cmd.info "cs-api" ~version:"%%VERSION_NUM%%"
let default_cmd = default_info

let () =
  Cmdliner.Cmd.group ~default:default_term default_cmd
    [analyze_cmd; list_profiles_cmd; upload_trace_cmd]
  |> Cmdliner.Cmd.eval'
  |> Stdlib.exit
