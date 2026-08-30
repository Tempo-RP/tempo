open Effect
open Tempo_types

type ('emit, 'agg, 'mode) signal_core =
  ('emit, 'agg, 'mode) Tempo_types.signal_core

type 'a signal = ('a, 'a, event) signal_core
type ('emit, 'agg) agg_signal = ('emit, 'agg, aggregate) signal_core

let ensure_signal_active : type emit agg mode.
    (emit, agg, mode) signal_core -> unit =
 fun s ->
  if not (Atomic.get s.owner.active) then
    invalid_arg "Tempo: signal belongs to a completed execution"

let new_signal : unit -> 'a signal = fun () -> perform (New_signal ())

let new_signal_agg :
    initial:'agg -> combine:('agg -> 'emit -> 'agg) -> ('emit, 'agg) agg_signal
    =
 fun ~initial ~combine -> perform (New_signal_agg (initial, combine))

let emit : type emit agg mode. (emit, agg, mode) signal_core -> emit -> unit =
 fun s v ->
  ensure_signal_active s;
  perform (Emit (s, v))

let await : type emit agg mode. (emit, agg, mode) signal_core -> agg =
 fun s ->
  ensure_signal_active s;
  perform (Await s)

let await_immediate : 'a signal -> 'a =
 fun s ->
  ensure_signal_active s;
  perform (Await_immediate s)

let pause : unit -> unit = fun () -> perform Pause

let when_ : type emit agg mode result.
    (emit, agg, mode) signal_core -> (unit -> result) -> result =
 fun s body ->
  ensure_signal_active s;
  perform (When (s, body))

let watch (s : ('emit, 'agg, 'mode) signal_core) (body : unit -> unit) : unit =
  ensure_signal_active s;
  perform (Watch (s, body))

let parallel procs = perform (Parallel procs)
