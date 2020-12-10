module Response = struct
    type t =
        { code : int
        ; response : string ref
        }
end

let response_accumulator_factory () =
    let resp = ref "" in
    let resp_callback s =
        resp := !resp ^ s;
        String.length s
    in
    (resp, resp_callback)

let set_headers curl header =
  Curl.set_httpheader
    curl
    (List.map
        (fun (h, v) -> h ^ ": " ^ v)
        header)

let set_part curl {Api.Part.name; content} =
  match content with
  | Direct s ->
          { Curl.encoding = Curl.CURLMIME_QUOTEDPRINTABLE
          ; headers = ["Content-Disposition: form-data; name=\"" ^ name ^ "\""]
          ; subparts = []
          ; data = Curl.CURLMIME_DATA s}
  | File {path; size} ->
          Curl.set_infilesize curl size;
          { encoding = Curl.CURLMIME_BINARY
          ; headers = ["Content-Disposition: form-data; name=\"file\"; filename=\"" ^ name ^ "\""]
          ; subparts = []
          ; data = Curl.CURLMIME_FILEDATA path}

let get_size {Api.Part.name; content} =
  match content with
  | Direct s ->
    String.length s + String.length name
  | File {size; _} ->
    size * 100

let get_total_size parts =
  parts
  |> List.map get_size
  |> List.fold_left (+) 0
  |> fun _ -> 4806

let set_multipart curl parts =
  List.map (set_part curl) parts
  |> Curl.set_mimepost curl

let send_request_exn ~verify {Api.Request.url; header; method_; data} =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let curl = Curl.init () in
  let response, response_callback = response_accumulator_factory () in
  Curl.set_url curl url;
  Curl.set_sslverifypeer curl verify;
  Curl.set_writefunction curl response_callback;
  set_headers curl header;
  let _ =
    match method_ with
      | Get ->
        Curl.set_httpget curl true
      | Post ->
        match data with
        | Raw str ->
          Curl.set_postfields curl str
        | Multipart parts ->
          let size = get_total_size parts in
          Curl.set_postfieldsize curl size;
          set_multipart curl parts
  in
  Curl.perform curl;
  Lwt_result.return { Response.code = Curl.get_responsecode curl; response = response }

let send_request ?(verify = true) request =
  send_request_exn ~verify request

let get_response {Response.code; response} =
  if code < 400 then
    Lwt_result.return !response
  else
    Lwt_result.fail !response
