type ('emit, 'agg, 'mode) signal_core =
  ('emit, 'agg, 'mode) Tempo_core.signal_core

val after_n : int -> (unit -> unit) -> unit
val every_n : int -> (unit -> unit) -> unit
val timeout : int -> on_timeout:(unit -> unit) -> (unit -> unit) -> unit
val cooldown : int -> ('emit, 'agg, 'mode) signal_core -> (unit -> unit) -> unit
val supervise_until : ('emit, 'agg, 'mode) signal_core -> (unit -> unit) -> unit

val loop : (unit -> unit) -> unit -> 'a
val idle : unit -> 'a
