open Tempo

let result = ref None

let () =
  execute ~instants:3 (fun _input _output ->
      let guard = new_signal () in
      let driver () =
        pause ();
        if !result <> None then failwith "body ran before the guard was present";
        emit guard ()
      in
      let worker () = result := Some (when_ guard (fun () -> "ready")) in
      parallel [ driver; worker ]);
  match !result with
  | Some "ready" -> Format.printf "late_guard=ready@.%!"
  | Some value -> failwith (Format.asprintf "unexpected result: %s" value)
  | None -> failwith "late guard did not release the computation"
