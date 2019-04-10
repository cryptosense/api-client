let rec convert_to_cohttp_form ?acc:(acc0=[]) form =
  match form with
  | [] -> acc0
  | (k, v)::t -> convert_to_cohttp_form ~acc:((k, [v])::acc0) t

let open_file file_path =
  let channel_promise = Lwt_io.open_file ~mode:Lwt_io.Input file_path in
  Lwt_main.run channel_promise

let sep = "---------------------------1960664607171245250372331177"

let multipart_file_upload_headers =
  [("Content-Type", "multipart/form-data; boundary=" ^ sep)]

let multipart_file_upload_form form_element =
  match form_element with
  | (k, v) -> "Content-Disposition: form-data; name=\"" ^ k ^ "\"\r\n\r\n" ^ v ^"\r\n--" ^ sep ^ "\r\n"

let multipart_file_upload_body form_data file_path =
  let file_content = open_file file_path in
  let parts = [ "--" ^ sep ^ "\r\n" ]
              @ List.map multipart_file_upload_form form_data 
              @ [ "Content-Disposition: form-data; name=\"file\"; filename=\"" ^ file_path ^ "\"\r\nContent-Type: application/octet-stream\r\n\r\n" ] in
  let parts_stream = Lwt_stream.of_list parts in
  let file_stream = Lwt_io.read_lines file_content in
  let end_stream = Lwt_stream.of_list [ "\r\n--" ^ sep ^ "--\r\n" ] in
  let entire_stream = Lwt_stream.of_list [ parts_stream; file_stream; end_stream ]  in
  Lwt_stream.concat entire_stream


let send_request {Api.Request.url; form; _method; header; file} =
  print_endline ("Requesting " ^ url ^ "...");
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) header in
  let url = Uri.of_string url in
  match _method with
  | Get ->
    Lwt_result.ok (Cohttp_lwt_unix.Client.get ~headers url)
  | Post -> (
      match file with
      | Some f ->
        let body = Cohttp_lwt.Body.of_stream (multipart_file_upload_body form f) in
        let headers = Cohttp.Header.add_list headers multipart_file_upload_headers in
        Lwt_result.ok (Cohttp_lwt_unix.Client.post ~body ~headers url)
      | None ->
        let form = convert_to_cohttp_form form in
        Lwt_result.ok (Cohttp_lwt_unix.Client.post_form ~headers ~params:form url)
    )

let get_response (resp, body) =
  let code = resp |> Cohttp.Response.status |> Cohttp.Code.code_of_status in
  match code with
  | c
    when c > 399 ->
    print_endline (resp |> Cohttp.Response.status |> Cohttp.Code.string_of_status);
    print_endline (body |> Cohttp_lwt.Body.to_string |> Lwt_main.run);
    Lwt.return (Error (resp |> Cohttp.Response.status |> Cohttp.Code.string_of_status))
  | _ ->
    Lwt_result.ok (body |> Cohttp_lwt.Body.to_string)


