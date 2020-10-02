type t =
  { endpoint : string
  ; key : string }

val make : api_endpoint:string -> api_key:string -> t

module Request : sig
  type method_ =
    | Get
    | Post

  type file =
    { path : string
    ; size : int }

  type t =
    { url : string
    ; form : (string * string) list
    ; method_ : method_
    ; header : (string * string) list
    ; file : file option }
end

module S3Signature : sig
  type t = (string * string) list
end
