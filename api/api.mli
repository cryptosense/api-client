type t =
  { endpoint : string
  ; key : string }

val make : api_endpoint:string -> api_key:string -> t

module File : sig
  type t =
    { path : string
    ; size : int }
end

module Data : sig
  type t =
    | Multipart of
        { form : (string * string) list
        ; file : File.t option }
end

module Method : sig
  type t =
    | Get
    | Post
end

module Request : sig
  type t =
    { url : string
    ; method_ : Method.t
    ; header : (string * string) list
    ; data : Data.t }
end

module S3Signature : sig
  type t = (string * string) list
end
