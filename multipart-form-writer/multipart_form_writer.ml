module MultipartRequest = struct

  type form_element =
    { key : string
    ; value : string
    }

  type file_element =
    { path : string
    ; name : string
    }

  type element =
    | Form of form_element
    | File of file_element

  type t =
    { elements : element list
    ; separator : string
    }

end

let init () =
  Random.self_init();
  (* It does not matter if the random numbers are not safe here *)
  { MultipartRequest.elements = []
  ; separator = "-----------------" ^ (string_of_int (Random.int 536870912))
  }

let init_with_separator separator =
  { MultipartRequest.elements = []
  ; separator = separator
  }

let add_form_element ~name ~value mp =
  let open MultipartRequest in
  { mp with elements = Form { key=name; value=value } :: mp.elements}

let add_file_from_disk ~name ~path mp =
  let open MultipartRequest in
  { mp with
    elements =
      File { path=path
           ; name=name
           }
      :: mp.elements
  }

let open_file path =
  (* This function returns a buffered IO read of a file *)
  let open Lwt.Infix in
  let read_while_not_empty channel () =
    (Lwt_io.read ~count:4096 channel)
    >|= (fun chunck ->
        match chunck with
        | "" -> None
        | _ -> Some chunck
      )
  in
  path
  |> Lwt_io.open_file ~mode:Lwt_io.Input
  >|= read_while_not_empty
  >|= Lwt_stream.from
  |> Lwt_result.ok


let safe_open_file path =
  try%lwt open_file path with
  | Unix.Unix_error(Unix.ENOENT, _, _) -> Lwt_result.fail ("File " ^ path ^ " not found")
  | Unix.Unix_error(Unix.EACCES, _, _) -> Lwt_result.fail ("Permission denied on " ^ path)
  | Unix.Unix_error(Unix.EBUSY, _, _) -> Lwt_result.fail ("File " ^ path ^ " was busy")
  | Unix.Unix_error(Unix.EISDIR, _, _) -> Lwt_result.fail ("File " ^ path ^ " is a directory")
  | _ -> Lwt_result.fail ("Unknown error while reading file " ^ path)

let file_size path =
  path
  |> Lwt_io.file_length
  |> Lwt.map Int64.to_int
  |> Lwt_result.ok

let safe_file_size path =
  try%lwt file_size path with
  | Unix.Unix_error(Unix.ENOENT, _, _) -> Lwt_result.fail ("File " ^ path ^ " not found")
  | Unix.Unix_error(Unix.EACCES, _, _) -> Lwt_result.fail ("Permission denied on " ^ path)
  | Unix.Unix_error(Unix.EBUSY, _, _) -> Lwt_result.fail ("File " ^ path ^ " was busy")
  | Unix.Unix_error(Unix.EISDIR, _, _) -> Lwt_result.fail ("File " ^ path ^ " is a directory")
  | _ -> Lwt_result.fail ("Unknown error while reading file " ^ path)

let element_separator_line separator element =
  match element with
  | MultipartRequest.Form {key; value}
    ->
    "--"
    ^ separator
    ^ "\r\nContent-Disposition: form-data; name=\""
    ^ key
    ^ "\"\r\n\r\n"
    ^ value
    ^ "\r\n"
  | File f
    ->
    "--"
    ^ separator
    ^ "\r\nContent-Disposition: form-data; name=\"file\"; filename=\""
    ^ f.name
    ^ "\"\r\nContent-Type: application/octet-stream\r\n\r\n"

let closing_line separator =
  "\r\n--" ^ separator ^ "--\r\n"

let closing_line_size separator =
  String.length (closing_line separator)


let element_to_string separator element =
  match element with
  | MultipartRequest.Form _
    ->
    Lwt_result.return (
      Lwt_stream.of_list [element_separator_line separator element]
    )
  | File {path; _}
    ->
    let open Lwt_result.Infix in
    let file_header = element_separator_line separator element in
    let file_header_stream = Lwt_stream.of_list [file_header] in
    safe_open_file path
    >|= fun (file_stream) -> Lwt_stream.append file_header_stream file_stream

let element_size separator element =
  match element with
  | MultipartRequest.Form _
    ->
    Lwt_result.return (
      String.length (element_separator_line separator element)
    )
  | File {path; _}
    ->
    let open Lwt_result.Infix in
    let file_header = (element_separator_line separator element) in
    let file_header_size = String.length file_header in
    safe_file_size path
    >|= fun (file_size) -> file_header_size + file_size


let rec mfoldl f acc l =
  match l with
  | h::t
    ->
    Lwt_result.bind
      h
      (fun value -> mfoldl f (f value acc) t)
  | []
    ->
    Lwt_result.return acc


let r_body mp =
  let {MultipartRequest.elements; separator} = mp in
  elements
  |> List.map (element_to_string separator)
  |> mfoldl Lwt_stream.append (Lwt_stream.of_list [closing_line separator])

let r_headers mp =
  let {MultipartRequest.elements; separator} = mp in
  let open Lwt_result.Infix in
  elements
  |> List.map (element_size separator)
  |> mfoldl (+) (closing_line_size separator)
  >|= (fun (total_size) ->
      [ ("Content-Type", "multipart/form-data; boundary=" ^ separator)
      ; ("Content-Length", string_of_int total_size)])
