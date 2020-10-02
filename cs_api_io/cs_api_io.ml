let rec convert_to_cohttp_form ?acc:(acc0 = []) form =
  match form with
  | [] -> acc0
  | (k, v) :: t -> convert_to_cohttp_form ~acc:((k, [v]) :: acc0) t

let get_ctx ~verify =
  let open Lwt.Infix in
  Conduit_lwt_unix.init ~verify () >|= fun ctx ->
  Cohttp_lwt_unix.Client.custom_ctx ~ctx ()

let send_request_exn
    ~verify
    {Api.Request.url; data = Multipart {form; file}; method_; header} =
  let open Lwt.Infix in
  let method_str =
    match method_ with
    | Get -> "GET"
    | Post -> "POST"
  in
  Printf.printf "Request: %s %s\n%!" method_str url;
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) header in
  let url = Uri.of_string url in
  get_ctx ~verify >>= fun ctx ->
  match method_ with
  | Get -> Lwt_result.ok (Cohttp_lwt_unix.Client.get ~ctx ~headers url)
  | Post -> (
    match file with
    | Some {path; _} ->
      let multipart =
        List.fold_left
          (fun mp (name, value) ->
            Multipart_form_writer.add_form_element ~name ~value mp)
          (Multipart_form_writer.init ())
          form
      in
      let multipart =
        Multipart_form_writer.add_file_from_disk ~name:"trace" ~path multipart
      in
      let open Lwt_result.Infix in
      Multipart_form_writer.r_body multipart >>= fun mp_body ->
      Multipart_form_writer.r_headers multipart >>= fun mp_headers ->
      let co_headers = Cohttp.Header.add_list headers mp_headers in
      let co_body = Cohttp_lwt.Body.of_stream mp_body in
      Lwt_result.ok
        (Cohttp_lwt_unix.Client.post ~ctx ~body:co_body ~headers:co_headers url)
    | None ->
      let form = convert_to_cohttp_form form in
      Lwt_result.ok
        (Cohttp_lwt_unix.Client.post_form ~ctx ~headers ~params:form url) )

let send_request ?(verify = true) request =
  Lwt.catch
    (fun () -> send_request_exn ~verify request)
    (function
      | error ->
        let message =
          match error with
          | Failure _ ->
            "URL could not be reached"
            (* Matching a specific failure results in warnings *)
          | Tls_lwt.Tls_failure _ -> "Could not establish HTTPS connection"
          | Unix.Unix_error (Unix.ECONNREFUSED, "connect", "") ->
            "Could not establish network connection"
          | Ssl.Connection_error _ -> Printexc.to_string error
          | _ ->
            Printf.sprintf "Unexpected exception: %s" (Printexc.to_string error)
        in
        Lwt_result.fail message)

let get_response (response, body) =
  let open Lwt.Infix in
  let status = Cohttp.Response.status response in
  let code = Cohttp.Code.code_of_status status in
  Cohttp_lwt.Body.to_string body >>= fun body_str ->
  if Cohttp.Code.is_error code then
    let message =
      Printf.sprintf "%s\n%s" (Cohttp.Code.string_of_status status) body_str
    in
    Lwt_result.fail message
  else
    Lwt_result.return body_str
