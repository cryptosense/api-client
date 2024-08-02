type t =
  { endpoint : string
  ; key : string }

let make ~api_endpoint ~api_key = {endpoint = api_endpoint; key = api_key}

module File = struct
  type t =
    { path : string
    ; size : int }
  [@@deriving eq, ord, show]
end

module Content = struct
  type t =
    | Direct of string
    | File of File.t
  [@@deriving eq, ord, show]
end

module Part = struct
  type t =
    { name : string
    ; content : Content.t }
  [@@deriving eq, ord, show]
end

module Data = struct
  type t =
    | Raw of string
    | File of File.t
    | Multipart of Part.t list
  [@@deriving eq, ord, show]

  let multipart_from_assoc assoc =
    assoc |> List.map (fun (name, value) -> {Part.name; content = Direct value})
end

module Method = struct
  type t =
    | Get
    | Post
    | Put
  [@@deriving eq, ord, show]

  let to_string = function
    | Get -> "GET"
    | Put -> "PUT"
    | Post -> "POST"
end

module Request = struct
  type t =
    { url : string
    ; header : (string * string) list
    ; method_ : Method.t
    ; data : Data.t }
  [@@deriving eq, ord, show]
end

module S3Signature = struct
  type t = (string * string) list
end
