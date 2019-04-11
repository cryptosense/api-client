val send_request : Api.Request.t -> (((Cohttp.Response.t * Cohttp_lwt.Body.t), string) result) Lwt.t
val get_response : (Cohttp.Response.t * Cohttp_lwt.Body.t) -> ((string, string) result) Lwt.t
