open Tempo

let result = ref None

let () =
  execute ~instants:4 (fun _input _output ->
      let outer = new_signal () in
      let inner = new_signal () in
      let driver () =
        pause ();
        emit outer ();
        pause ();
        emit outer ();
        emit inner ()
      in
      let worker () =
        result :=
          Some
            (when_ outer (fun () ->
                 let value = when_ inner (fun () -> 21) in
                 value * 2))
      in
      parallel [ driver; worker ]);
  match !result with
  | Some 42 -> Format.printf "nested=42@.%!"
  | Some value -> failwith (Format.asprintf "unexpected result: %d" value)
  | None -> failwith "nested guarded computation did not return"
