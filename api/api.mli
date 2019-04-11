type t = 
  { endpoint : string
  ; key : string
  }

val make : api_endpoint:string -> api_key:string -> t

module Request : sig
  type _method =
    | Get
    | Post

  type file =
    { path : string
    ; size : int
    }

  type t =
    { url : string
    ; form : (string * string) list
    ; _method : _method
    ; header : (string * string) list
    ; file : file option }
end

module S3Signature : sig

  type t = (string * string) list

end
