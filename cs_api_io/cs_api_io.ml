let rec convert_to_cohttp_form ?acc:(acc0=[]) form =
  match form with
  | [] -> acc0
  | (k, v)::t -> convert_to_cohttp_form ~acc:((k, [v])::acc0) t


let unsafe_send_request {Api.Request.url; form; method_; header; file} =
  print_endline ("Requesting " ^ url ^ "...");
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) header in
  let url = Uri.of_string url in
  match method_ with
  | Get
    ->
    Lwt_result.ok (Cohttp_lwt_unix.Client.get ~headers url)
  | Post
    ->
    (
      match file with
      | Some {Api.Request.path; _}
        ->
        let multipart =
          List.fold_left
            (fun mp (name, value) -> Multipart_form_writer.add_form_element ~name ~value mp)
            (Multipart_form_writer.init ())
            form
        in
        let multipart = Multipart_form_writer.add_file_from_disk ~name:"trace" ~path multipart in
        let open Lwt_result.Infix in
        Multipart_form_writer.r_body multipart
        >>= fun mp_body -> Multipart_form_writer.r_headers multipart
        >>= fun mp_headers ->
        let co_headers =
          Cohttp.Header.add_list headers mp_headers
        in
        let co_body =
          Cohttp_lwt.Body.of_stream mp_body
        in
        Lwt_result.ok (Cohttp_lwt_unix.Client.post ~body:co_body ~headers:co_headers url)
      | None
        ->
        let form = convert_to_cohttp_form form in
        Lwt_result.ok (Cohttp_lwt_unix.Client.post_form ~headers ~params:form url)
    )

let send_request request =
  Lwt.catch
    (fun () -> unsafe_send_request request)
    (function
      | Failure _
        ->
        Lwt_result.fail "URL could not be reached" (* Matching a specific failure results in warnings *)
      | Tls_lwt.Tls_failure(_)
        ->
        Lwt_result.fail "Could not establish HTTPS connection"
      | Unix.Unix_error(Unix.ECONNREFUSED, "connect", "")
        ->
        Lwt_result.fail "Could not establish network connection"
      | _
        ->
        Lwt_result.fail "Unknown error !"
    )

let get_response (response, body) =
  let open Lwt.Infix in
  let status = Cohttp.Response.status response in
  let code = Cohttp.Code.code_of_status status in
  Cohttp_lwt.Body.to_string body >>= fun body_str ->
  if Cohttp.Code.is_error code then
    let message = Printf.sprintf "%s\n%s" (Cohttp.Code.string_of_status status) body_str in
    Lwt_result.fail message
  else
    Lwt_result.return body_str
