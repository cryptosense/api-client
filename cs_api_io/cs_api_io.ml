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

let send_request_raw
    ~curl
    ~(config : Config.t)
    {Api.Request.url; header; method_; data} =
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
  let _ =
    match method_ with
    | Get -> Curl.set_httpget curl true
    | Post -> (
      match data with
      | Raw str -> Curl.set_postfields curl str
      | Multipart parts -> set_multipart curl parts)
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

let send_request ~config request =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let curl = Curl.init () in
  Fun.protect
    (fun () -> send_request_raw ~curl ~config request)
    ~finally:(fun () -> Curl.cleanup curl)

let get_response {Response.code; body} =
  if code < 300 then
    Lwt_result.return body
  else
    let message = Printf.sprintf "HTTP response: %d\n%s" code body in
    Lwt_result.fail message
