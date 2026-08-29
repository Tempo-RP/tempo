open Tempo

exception Combine_failure

let duplicate_emit_caught = ref false
let duplicate_sibling_suffix = ref false
let combine_caught = ref false
let combine_sibling_suffix = ref false
let direct_duplicate_caught = ref false
let direct_combine_caught = ref false

let direct_style_failures () =
  execute ~instants:1 (fun _input _output ->
      let event = new_signal () in
      emit event ();
      (try emit event ()
       with Invalid_argument _ -> direct_duplicate_caught := true);
      let aggregate =
        new_signal_agg ~initial:() ~combine:(fun () () -> raise Combine_failure)
      in
      try emit aggregate ()
      with Combine_failure -> direct_combine_caught := true);
  if not !direct_duplicate_caught then
    failwith "duplicate emit was not catchable in direct style";
  if not !direct_combine_caught then
    failwith "aggregate combine failure was not catchable in direct style"

let duplicate_emit_failure () =
  execute ~instants:3 (fun _input _output ->
      let event = new_signal () in
      try
        parallel
          [
            (fun () ->
              emit event ();
              emit event ())
          ; (fun () ->
              pause ();
              duplicate_sibling_suffix := true)
          ]
      with Invalid_argument _ -> duplicate_emit_caught := true);
  if not !duplicate_emit_caught then
    failwith "duplicate emit bypassed the parallel call site";
  if !duplicate_sibling_suffix then
    failwith "duplicate emit did not stop its parallel sibling"

let aggregate_combine_failure () =
  execute ~instants:3 (fun _input _output ->
      let aggregate =
        new_signal_agg ~initial:() ~combine:(fun () () -> raise Combine_failure)
      in
      try
        parallel
          [
            (fun () -> emit aggregate ())
          ; (fun () ->
              pause ();
              combine_sibling_suffix := true)
          ]
      with Combine_failure -> combine_caught := true);
  if not !combine_caught then
    failwith "aggregate combine failure bypassed the parallel call site";
  if !combine_sibling_suffix then
    failwith "aggregate combine failure did not stop its parallel sibling"

let () =
  direct_style_failures ();
  duplicate_emit_failure ();
  aggregate_combine_failure ();
  Format.printf "direct_duplicate_caught=%b direct_combine_caught=%b@.%!"
    !direct_duplicate_caught !direct_combine_caught;
  Format.printf "duplicate_caught=%b duplicate_sibling_suffix=%b@.%!"
    !duplicate_emit_caught !duplicate_sibling_suffix;
  Format.printf "combine_caught=%b combine_sibling_suffix=%b@.%!"
    !combine_caught !combine_sibling_suffix
