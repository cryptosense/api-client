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

let send_request_exn ~verify {Api.Request.url; header; method_; data} =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let curl = Curl.init () in
  let (response, response_callback) = response_accumulator_factory () in
  Curl.set_url curl url;
  Curl.set_sslverifypeer curl verify;
  Curl.set_sslverifyhost curl
    ( if verify then
      SSLVERIFYHOST_HOSTNAME
    else
      SSLVERIFYHOST_NONE );
  Curl.set_writefunction curl response_callback;
  set_headers curl header;
  let _ =
    match method_ with
    | Get -> Curl.set_httpget curl true
    | Post -> (
      match data with
      | Raw str -> Curl.set_postfields curl str
      | Multipart parts -> set_multipart curl parts )
  in
  try
    Curl.perform curl;
    Lwt_result.return
      {Response.code = Curl.get_responsecode curl; body = !response}
  with Curl.CurlException (case, code, str) ->
    let message =
      match case with
      | CURLE_URL_MALFORMAT -> "Malformed URL"
      | CURLE_COULDNT_RESOLVE_HOST -> "Could not resolve host"
      | CURLE_COULDNT_RESOLVE_PROXY -> "Unable to resolve proxy host"
      | CURLE_COULDNT_CONNECT -> "Could not connect to host or proxy"
      | CURLE_SSL_CONNECT_ERROR -> "Failure in the TLS handshake"
      | CURLE_OPERATION_TIMEOUTED -> "Request timed out"
      | CURLE_SEND_ERROR -> "Unable to send data to the network"
      | CURLE_RECV_ERROR -> "Unable to receive data from the network"
      | CURLE_SSL_PEER_CERTIFICATE
      | CURLE_SSL_CACERT ->
        "Could not validate TLS certificate"
      | _ -> Printf.sprintf "Unknown error: %s (%d)" str code
    in
    Lwt_result.fail ("HTTP error: " ^ message)

let send_request ?(verify = true) request = send_request_exn ~verify request

let get_response {Response.code; body} =
  if code < 300 then
    Lwt_result.return body
  else
    let message = Printf.sprintf "HTTP response: %d\n%s" code body in
    Lwt_result.fail message
