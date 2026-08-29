open Tempo

let result = ref None

let () =
  execute (fun _input _output ->
      let guard = new_signal () in
      emit guard ();
      result := Some (when_ guard (fun () -> 42)));
  match !result with
  | Some 42 -> Format.printf "immediate=42@.%!"
  | Some value -> failwith (Format.asprintf "unexpected result: %d" value)
  | None -> failwith "guarded computation did not return"
