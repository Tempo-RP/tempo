open Tempo

let result = ref None

let () =
  execute ~instants:3 (fun _input _output ->
      let guard = new_signal () in
      let payload = new_signal () in
      let driver () =
        emit guard ();
        emit payload 7;
        pause ();
        emit guard ()
      in
      let worker () = result := Some (when_ guard (fun () -> await payload)) in
      parallel [ driver; worker ]);
  match !result with
  | Some 7 -> Format.printf "await=7@.%!"
  | Some value -> failwith (Format.asprintf "unexpected result: %d" value)
  | None -> failwith "await result did not leave the guarded computation"
