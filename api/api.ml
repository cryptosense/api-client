type t =
  { endpoint : string
  ; key : string }

let make ~api_endpoint ~api_key = {endpoint = api_endpoint; key = api_key}

module File = struct
  type t =
    { path : string
    ; size : int }
end

module Data = struct
  type t =
    | Multipart of
        { form : (string * string) list
        ; file : File.t option }
end

module Method = struct
  type t =
    | Get
    | Post
end

module Request = struct
  type t =
    { url : string
    ; method_ : Method.t
    ; header : (string * string) list
    ; data : Data.t }
end

module S3Signature = struct
  type t = (string * string) list
end
