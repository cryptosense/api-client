
type t =
  { endpoint : string
  ; key : string
  }

let make ~api_endpoint ~api_key =
  { endpoint = api_endpoint
  ; key = api_key
  }

module Request  = struct
  type _method =
    | Get
    | Post

  type t =
    { url : string
    ; form : (string * string) list
    ; _method : _method
    ; header : (string * string) list
    ; file : string option }
end

module S3Signature = struct

 type t = (string * string) list

end
