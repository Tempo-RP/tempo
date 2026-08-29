let delay (body : unit -> 'a) : 'a Tempo.computation = body
let expose (body : 'a Tempo.computation) : unit -> 'a = body
let (_ : unit Tempo.computation list -> unit) = Tempo.parallel
let (_ : int Tempo.signal -> unit Tempo.computation -> unit) = Tempo.when_
let (_ : int Tempo.signal -> unit Tempo.computation -> unit) = Tempo.watch

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
