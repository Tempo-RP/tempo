module Tempo = struct
  let parallel computations =
    List.iter (fun computation -> computation ()) computations
end

let () = [%tempo.parallel [ ignore 1; ignore 2 ]]
