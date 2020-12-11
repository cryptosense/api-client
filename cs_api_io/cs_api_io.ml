module Response = struct
    type t =
        { code : int
        ; response : string
        }
end

let curl_verify_certs = function
  | true -> ""
  | false -> "-k"

let curl_http_method = function
  | Api.Method.Get -> "-XGET"
  | Post -> "-XPOST"

let curl_header (h, v) =
  "-H \"" ^ h ^ ": " ^ v ^ "\""

let curl_url u = u

let curl_post_data data =
  "--data '" ^ data ^ "'"

let curl_multipart {Api.Part.name; content} =
  match content with
  | Direct s ->
    "-F \"" ^ name ^ "=" ^ s ^ "\""
  | File {path; _} ->
    "-F \"file=@" ^ path ^ "\""

let curl_suppress_output _ =
    "--no-progress-meter"

let add_argument arg cmd =
  match arg with
  | "" -> cmd
  | _ -> cmd ^ " " ^ arg

let send_request_exn ~verify {Api.Request.url; header; method_; data} =
  "curl"
  |> add_argument (curl_suppress_output ())
  |> add_argument (curl_verify_certs verify)
  |> add_argument (curl_http_method method_)
  |> (fun c -> List.fold_left (fun acc h -> add_argument (curl_header h) acc) c header)
  |> (fun c ->
      match method_ with
        | Get -> c
        | Post ->
          match data with
          | Raw str -> add_argument (curl_post_data str) c
          | Multipart parts ->
            List.fold_left (fun acc p -> add_argument (curl_multipart p) acc) c parts)
  |> add_argument (curl_url url)
  |> (fun c -> print_endline ""; print_endline c; c)
  |> Cs_api_bash.execute
  |> (fun r -> print_endline "_____ RESPONSE"; print_endline r; print_endline ""; r)
  |> (fun r -> Lwt_result.return {Response.code = 200; response = r})

let send_request ?(verify = true) request =
  send_request_exn ~verify request

let get_response {Response.code; response} =
  if code < 400 then
    Lwt_result.return response
  else
    Lwt_result.fail response
