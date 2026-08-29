module Tempo = struct
  let parallel computations =
    List.iter (fun computation -> computation ()) computations

  let when_ _signal computation = computation ()
  let watch _signal computation = computation ()
end

let signal = ()
let () = [%tempo.parallel [ ignore 1; ignore 2 ]]
let _ = [%tempo.when signal (ignore 3)]
let () = [%tempo.watch signal (ignore 4)]
