module Make (_ : sig
  val section : string
end) : sig
  val fatal : ('a, unit, string, unit) format4 -> 'a
  val error : ('a, unit, string, unit) format4 -> 'a
  val warn : ('a, unit, string, unit) format4 -> 'a
  val info : ('a, unit, string, unit) format4 -> 'a
  val debug : ('a, unit, string, unit) format4 -> 'a
end
