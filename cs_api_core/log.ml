(* Log a message using Logs. *)
let log (logger : (string -> unit) Logs.log) fmt =
  Printf.ksprintf (fun s -> logger (fun m -> m "%s" s)) fmt

module Make (M : sig
  val section : string
end) =
struct
  let src = Logs.Src.create M.section

  module Log = (val Logs.src_log src : Logs.LOG)

  let fatal fmt = log Log.err fmt
  let error fmt = log Log.err fmt
  let warn fmt = log Log.warn fmt
  let info fmt = log Log.info fmt
  let debug fmt = log Log.debug fmt
end
