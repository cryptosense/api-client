module Response : sig
  type t
end

val send_request :
     ?progress_bar:bool
  -> ?verify:bool
  -> Api.Request.t
  -> (Response.t, string) result Lwt.t

val get_response : Response.t -> (string, string) result Lwt.t
