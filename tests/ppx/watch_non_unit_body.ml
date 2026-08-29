module Tempo = struct
  let watch _signal (computation : unit -> unit) = computation ()
end

let stop = ()
let _ = [%tempo.watch stop 42]
