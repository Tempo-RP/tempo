open Tempo

let result = ref None
let after_scope = ref false
let body_entries = ref 0

let () =
  execute ~instants:4 (fun _input _output ->
      let guard = new_signal () in
      let driver () =
        emit guard ();
        pause ();
        emit guard ()
      in
      let worker () =
        let value =
          when_ guard (fun () ->
              incr body_entries;
              pause ();
              42)
        in
        result := Some value;
        pause ();
        after_scope := true
      in
      parallel [ driver; worker ]);
  (match !result with
  | Some 42 -> ()
  | Some value -> failwith (Format.asprintf "unexpected result: %d" value)
  | None -> failwith "suspended guarded computation did not return");
  if !body_entries <> 1 then failwith "guarded computation was restarted";
  if not !after_scope then failwith "guard leaked beyond the when_ body";
  Format.printf "suspended=42 entries=%d after_scope=%b@.%!" !body_entries
    !after_scope
