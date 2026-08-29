let delay (body : unit -> 'a) : 'a Tempo.computation = body
let expose (body : 'a Tempo.computation) : unit -> 'a = body
let (_ : unit Tempo.computation list -> unit) = Tempo.parallel
let (_ : int Tempo.signal -> unit Tempo.computation -> unit) = Tempo.when_
let (_ : int Tempo.signal -> unit Tempo.computation -> unit) = Tempo.watch
let (_ : int -> unit Tempo.computation -> unit) = Tempo.Constructs.after_n
let (_ : int -> unit Tempo.computation -> unit) = Tempo.Constructs.every_n

let (_ :
      int -> on_timeout:unit Tempo.computation -> unit Tempo.computation -> unit)
    =
  Tempo.Constructs.timeout

let (_ : int -> int Tempo.signal -> unit Tempo.computation -> unit) =
  Tempo.Constructs.cooldown

let (_ : int Tempo.signal -> unit Tempo.computation -> unit) =
  Tempo.Constructs.supervise_until

let (_ : unit Tempo.computation -> 'a Tempo.computation) = Tempo.Constructs.loop
let (_ : 'a Tempo.computation) = Tempo.Constructs.idle

let (_ :
         ?instants:int
      -> ?input:(unit -> int option)
      -> ?output:(string -> unit)
      -> ?on_snapshot:(Tempo.runtime_snapshot -> unit)
      -> (int Tempo.signal -> string Tempo.signal -> unit)
      -> unit) =
  Tempo.execute

let () =
  let answer = delay (fun () -> 42) in
  if expose answer () <> 42 then failwith "computation alias changed evaluation"
