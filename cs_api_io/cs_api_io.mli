module Config : sig
  type t =
    { verify : bool
    ; ca_file : string option }
end

module Response : sig
  type t
end

val send_request :
  config:Config.t -> Api.Request.t -> (Response.t, string) result Lwt.t

val get_response : Response.t -> (string, string) result Lwt.t
