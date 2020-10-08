let get_ctx ~verify =
  let open Lwt.Infix in
  Conduit_lwt_unix.init ~verify () >|= fun ctx ->
  Cohttp_lwt_unix.Client.custom_ctx ~ctx ()

let add_part ~multipart {Api.Part.name; content} =
  match content with
  | Direct value ->
    Multipart_form_writer.add_form_element ~name ~value multipart
  | File {path; size = _} ->
    Multipart_form_writer.add_file_from_disk ~name ~path multipart

let handle_raw str = Lwt_result.return ([], Lwt_stream.of_list [str])

let handle_multipart parts =
  let open Lwt_result.Infix in
  let multipart =
    List.fold_left
      (fun multipart part -> add_part ~multipart part)
      (Multipart_form_writer.init ())
      parts
  in
  Multipart_form_writer.r_body multipart >>= fun body ->
  Multipart_form_writer.r_headers multipart >|= fun headers -> (headers, body)

let send_request_exn ~verify {Api.Request.url; header; method_; data} =
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
  let open Lwt_result.Infix in
  match method_ with
  | Get -> Lwt_result.ok (Cohttp_lwt_unix.Client.get ~ctx ~headers url)
  | Post ->
    ( match data with
    | Raw str -> handle_raw str
    | Multipart parts -> handle_multipart parts )
    >>= fun (extra_headers, body) ->
    let headers = Cohttp.Header.add_list headers extra_headers in
    let body = Cohttp_lwt.Body.of_stream body in
    Lwt_result.ok (Cohttp_lwt_unix.Client.post ~ctx ~body ~headers url)

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
