open Tempo

exception Nested_failure
exception Inner_priority
exception Outer_priority
exception Guarded_failure
exception Watched_failure

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let nested_failure () =
  let now = ref (-1) in
  let inner_prefix = ref false in
  let inner_suffix = ref false in
  let outer_prefix = ref false in
  let outer_suffix = ref false in
  let caught_at = ref (-1) in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      try
        parallel
          [
            (fun () ->
              parallel
                [
                  (fun () -> raise Nested_failure)
                ; (fun () ->
                    inner_prefix := true;
                    pause ();
                    inner_suffix := true)
                ])
          ; (fun () ->
              outer_prefix := true;
              pause ();
              outer_suffix := true)
          ]
      with Nested_failure -> caught_at := !now);
  if !caught_at <> 0 then
    failwith "nested parallel failure did not cross both scopes in one instant";
  if (not !inner_prefix) || !inner_suffix then
    failwith "inner sibling survived nested parallel failure";
  if (not !outer_prefix) || !outer_suffix then
    failwith "outer sibling survived nested parallel failure";
  !caught_at

let nested_priority () =
  let selected = ref (-1) in
  execute ~instants:3 (fun _input _output ->
      try
        parallel
          [
            (fun () ->
              parallel
                [ (fun () -> raise Inner_priority); (fun () -> pause ()) ])
          ; (fun () -> raise Outer_priority)
          ]
      with
      | Inner_priority -> selected := 0
      | Outer_priority -> selected := 1);
  if !selected <> 0 then
    failwith "outer parallel resolved before its nested failure";
  !selected

let guarded_failure () =
  let now = ref (-1) in
  let sibling_prefix = ref false in
  let sibling_suffix = ref false in
  let caught_at = ref (-1) in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      let guard = new_signal () in
      emit guard ();
      try
        when_ guard (fun () ->
            parallel
              [
                (fun () -> raise Guarded_failure)
              ; (fun () ->
                  sibling_prefix := true;
                  pause ();
                  sibling_suffix := true)
              ])
      with Guarded_failure -> caught_at := !now);
  if !caught_at <> 0 then
    failwith "parallel failure was delayed beyond its enclosing guard";
  if (not !sibling_prefix) || !sibling_suffix then
    failwith "guarded parallel sibling survived failure";
  !caught_at

let watched_failure failure_first =
  let now = ref (-1) in
  let caught_at = ref (-1) in
  let normal_return = ref false in
  let sibling_suffix = ref false in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      let stop = new_signal () in
      let fail () = raise Watched_failure in
      let emit_stop () = emit stop () in
      let sibling () =
        pause ();
        sibling_suffix := true
      in
      try
        watch stop (fun () ->
            parallel
              (if failure_first then [ fail; emit_stop; sibling ]
               else [ emit_stop; fail; sibling ]));
        normal_return := true
      with Watched_failure -> caught_at := !now);
  if !caught_at <> 0 || !normal_return then
    failwith "watch preemption incorrectly won over a branch failure";
  if !sibling_suffix then
    failwith "watched parallel sibling survived branch failure";
  !caught_at

let () =
  let nested_at = nested_failure () in
  let nested_selected = nested_priority () in
  let guarded_at = guarded_failure () in
  let watched_failure_first = watched_failure true in
  let watched_emission_first = watched_failure false in
  Format.printf "nested=%d nested_priority=%d guarded=%d@.%!" nested_at
    nested_selected guarded_at;
  Format.printf "watched_failure_first=%d watched_emission_first=%d@.%!"
    watched_failure_first watched_emission_first
