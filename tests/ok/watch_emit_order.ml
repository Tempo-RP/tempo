open Tempo

let run emit_first =
  let observed = ref [] in
  execute ~instants:3
    ~output:(fun value -> observed := value :: !observed)
    (fun _ output ->
      let stop = new_signal () in
      let emitter () = emit stop () in
      let watched () =
        watch stop (fun () ->
            emit output "body";
            pause ();
            emit output "unreachable");
        emit output "outside"
      in
      parallel
        (if emit_first then [ emitter; watched ] else [ watched; emitter ]));
  List.rev !observed

let check name result =
  let expected = [ "body"; "outside" ] in
  if result <> expected then
    failwith
      (Printf.sprintf "%s: expected body,outside, got %s" name
         (String.concat "," result));
  Format.printf "%s=body,outside@.%!" name

let () =
  check "emit_first" (run true);
  check "watch_first" (run false)
