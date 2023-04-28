module Config = struct
  type t =
    { verify : bool
    ; ca_file : string option }
end

module Response = struct
  type t =
    { code : int
    ; body : string }
end

type t =
  { config : Config.t
  ; curl : Curl.t }

let with_client ~config ~f =
  let curl = Curl.init () in
  Fun.protect
    (fun () -> f {config; curl})
    ~finally:(fun () -> Curl.cleanup curl)

let response_accumulator_factory () =
  let resp = ref "" in
  let resp_callback s =
    resp := !resp ^ s;
    String.length s
  in
  (resp, resp_callback)

let set_headers curl header =
  Curl.set_httpheader curl (List.map (fun (h, v) -> h ^ ": " ^ v) header)

let make_part {Api.Part.name; content} =
  match content with
  | Direct s -> Curl.CURLFORM_CONTENT (name, s, DEFAULT)
  | File {path; _} -> Curl.CURLFORM_FILE (name, path, DEFAULT)

let set_multipart curl parts =
  parts |> List.map make_part |> Curl.set_httppost curl

let build_file_reader path =
  let channel = open_in_bin path in
  let is_channel_open = ref true in
  let reader n =
    let buf = Bytes.create n in
    let bytes_in = input channel buf 0 n in
    Printf.printf "Read from channel (%d)\n" bytes_in;
    if Int.equal bytes_in 0 && !is_channel_open then close_in channel;
    is_channel_open := false;
    Printf.printf "Closing channel\n";
    Bytes.to_string buf
  in
  reader

let send_request ~client:{config; curl} {Api.Request.url; header; method_; data}
    =
  let (response, response_callback) = response_accumulator_factory () in
  Curl.set_url curl url;
  Curl.set_sslverifypeer curl config.verify;
  Curl.set_sslverifyhost curl
    (if config.verify then
       SSLVERIFYHOST_HOSTNAME
     else
       SSLVERIFYHOST_NONE);
  config.ca_file |> Option.iter (fun ca_file -> Curl.set_cainfo curl ca_file);
  Curl.set_writefunction curl response_callback;
  set_headers curl header;
  let set_data curl = function
    | Api.Data.Raw str -> Curl.set_postfields curl str
    | File {Api.File.path; size} ->
      Printf.printf "Size: %d\n" size;
      Curl.set_upload curl true;
      Curl.set_readfunction curl (build_file_reader path);
      Curl.set_infilesize curl size
    | Multipart parts -> set_multipart curl parts
  in
  let _ =
    match method_ with
    | Get -> Curl.set_httpget curl true
    | Put
    | Post ->
      set_data curl data
  in
  let error_message = ref "" (* This string will be replaced by `Curl`. *) in
  Curl.setopt curl (Curl.CURLOPT_ERRORBUFFER error_message);
  try
    Curl.perform curl;
    Lwt_result.return
      {Response.code = Curl.get_responsecode curl; body = !response}
  with
  | Curl.CurlException (_, _, error_name) ->
    Lwt_result.fail
      (Printf.sprintf "HTTP error (%s): %s" error_name !error_message)

let get_response {Response.code; body} =
  if code < 300 then
    Lwt_result.return body
  else
    let message = Printf.sprintf "HTTP response: %d\n%s" code body in
    Lwt_result.fail message

let get_graphql_errors (json : Yojson.Safe.t) =
  (match json with
  | `Assoc _ -> (Some (Yojson.Safe.Util.member "errors" json), [])
  | _ -> (None, ["Unexpected response from the server"]))
  |> function
  | (None, errors) -> errors
  | (Some `Null, _) -> []
  | (Some errors_json, _) -> (
    match errors_json with
    | `List error_list ->
      error_list
      |> CCList.map (Yojson.Safe.Util.member "message")
      |> CCList.map (function
           | `String error_message -> error_message
           | _ -> "Unexpected response from the server")
    | _ -> ["Unexpected response from the server"])

let get_response_graphql {Response.code; body} =
  if code < 300 then
    try
      let json = Yojson.Safe.from_string body in
      match get_graphql_errors json with
      | [] -> Lwt_result.return body
      | errors -> CCString.concat "\n" errors |> Lwt_result.fail
    with
    | _ -> Lwt_result.return body
  else
    let message = Printf.sprintf "HTTP response: %d\n%s" code body in
    Lwt_result.fail message
