module Config : sig
  type t =
    { verify : bool
    ; ca_file : string option }
end

module Response : sig
  type t
end

type t

val with_client : config:Config.t -> f:(t -> 'a) -> 'a
(** Initialize the client and clean up after the provided function [f] has been executed.

    This currently uses libcurl. The library must have been globally initalized before
    this wrapper is called. Cleanup of the "easy" session is guaranteed even if the
    provided function [f] raises an exception. *)

val send_request :
  client:t -> Api.Request.t -> (Response.t, string) result Lwt.t

val get_response : Response.t -> (string, string) result Lwt.t

val get_graphql_errors : Yojson.Safe.t -> string list

val get_response_graphql : Response.t -> (string, string) result Lwt.t
