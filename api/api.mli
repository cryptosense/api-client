type t =
  { endpoint : string
  ; key : string }

val make : api_endpoint:string -> api_key:string -> t

module File : sig
  type t =
    { path : string
    ; size : int }
  [@@deriving eq, ord, show]
end

module Content : sig
  type t =
    | Direct of string
    | File of File.t
  [@@deriving eq, ord, show]
end

module Part : sig
  type t =
    { name : string
    ; content : Content.t }
  [@@deriving eq, ord, show]
end

module Data : sig
  type t =
    | Raw of string
    | File of File.t
    | Multipart of Part.t list
  [@@deriving eq, ord, show]

  val multipart_from_assoc : (string * string) list -> Part.t list
end

module Method : sig
  type t =
    | Get
    | Post
    | Put

  val to_string : t -> string
  (** Human-readable representation of an HTTP method. *)
end

module Request : sig
  type t =
    { url : string
    ; header : (string * string) list
    ; method_ : Method.t
    ; data : Data.t }
  [@@deriving eq, ord, show]
end

module S3Signature : sig
  type t = (string * string) list
end
