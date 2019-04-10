val send_request : Api_parser.request -> (((Cohttp.Response.t * Cohttp_lwt.Body.t), 'a) result) Lwt.t
val get_response : (Cohttp.Response.t * Cohttp_lwt.Body.t) -> ((string, string) result) Lwt.t
