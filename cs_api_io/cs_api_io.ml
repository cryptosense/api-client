let rec convert_to_cohttp_form ?acc:(acc0=[]) form =
  match form with
  | [] -> acc0
  | (k, v)::t -> convert_to_cohttp_form ~acc:((k, [v])::acc0) t

let open_file file_path =
  let channel_promise = Lwt_io.open_file ~mode:Lwt_io.Input file_path in
  Lwt_main.run channel_promise

let sep = "---------------------------1960664607171245250372331177"

let multipart_file_upload_headers body_size =
  [ ("Content-Type", "multipart/form-data; boundary=" ^ sep)
  ; ("Content-Length", string_of_int body_size)
  ]

let multipart_file_upload_form (key, value) =
  "Content-Disposition: form-data; name=\"" ^ key ^ "\"\r\n\r\n" ^ value ^"\r\n--" ^ sep ^ "\r\n"

let multipart_file_upload_body form_data file_path file_size =
  let file_content = open_file file_path in
  let file_stream = 
    file_content |> Lwt_io.read_chars |> Lwt_stream.map (String.make 1)
  in
  let initial_header = "--" ^ sep ^ "\r\n" in
  let initial_header_size = String.length initial_header in
  let form_parts = List.map multipart_file_upload_form form_data in
  let form_parts_size = 
    form_parts
    |> List.map String.length
    |> List.fold_left (+) 0 in
  let file_header =
    "Content-Disposition: form-data; name=\"file\"; filename=\""
    ^ file_path
    ^ "\"\r\nContent-Type: application/octet-stream\r\n\r\n"
  in
  let file_header_size = String.length file_header in
  let final_header =  "\r\n--" ^ sep ^ "--\r\n" in
  let final_header_size = String.length final_header in
  let part1 =
    [ initial_header ]
    @ form_parts
    @ [ file_header ]
  in
  let part1_stream = Lwt_stream.of_list part1 in
  let part2_stream = Lwt_stream.of_list [ final_header ] in
  let entire_stream =
    Lwt_stream.of_list
      [ part1_stream
      ; file_stream
      ; part2_stream
      ]
  in
  let entire_size =
    initial_header_size + form_parts_size + file_header_size + final_header_size + file_size
  in
  entire_size, Lwt_stream.concat entire_stream



let unsafe_send_request {Api.Request.url; form; _method; header; file} =
  print_endline ("Requesting " ^ url ^ "...");
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) header in
  let url = Uri.of_string url in
  match _method with
  | Get
    ->
    Lwt_result.ok (Cohttp_lwt_unix.Client.get ~headers url)
  | Post
    ->
    (
      match file with
      | Some {Api.Request.path; size}
        ->
        let body_size, body = multipart_file_upload_body form path size in
        let body = Cohttp_lwt.Body.of_stream (body) in
        let headers = Cohttp.Header.add_list headers (multipart_file_upload_headers body_size) in
        Lwt_result.ok (Cohttp_lwt_unix.Client.post ~body ~headers url)
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

let get_response (resp, body) =
  let code = resp |> Cohttp.Response.status |> Cohttp.Code.code_of_status in
  match code with
  | c when c > 399
    ->
    print_endline (resp |> Cohttp.Response.status |> Cohttp.Code.string_of_status);
    print_endline (body |> Cohttp_lwt.Body.to_string |> Lwt_main.run);
    Lwt.return (Error (resp |> Cohttp.Response.status |> Cohttp.Code.string_of_status))
  | _ ->
    Lwt_result.ok (body |> Cohttp_lwt.Body.to_string)


