open Tempo

exception Branch_failure of int
exception Delayed_failure
exception Awaited_failure

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let trivial_completion () =
  let now = ref (-1) in
  let empty_at = ref (-1) in
  let singleton_at = ref (-1) in
  execute ~instants:1 ~on_snapshot:(record_instant now) (fun _input _output ->
      parallel [];
      empty_at := !now;
      parallel [ (fun () -> ()) ];
      singleton_at := !now);
  if !empty_at <> 0 || !singleton_at <> 0 then
    failwith "trivial parallel composition crossed an instant boundary";
  (!empty_at, !singleton_at)

let same_instant_selection () =
  let now = ref (-1) in
  let failure_order = ref [] in
  let selected = ref (-1) in
  let caught_at = ref (-1) in
  let sibling_prefix = ref false in
  let sibling_suffix = ref false in
  let escaped_execute = ref false in
  (try
     execute ~instants:3 ~on_snapshot:(record_instant now)
       (fun _input _output ->
         let gate = new_signal () in
         try
           parallel
             [
               (fun () ->
                 ignore (await_immediate gate);
                 failure_order := 0 :: !failure_order;
                 raise (Branch_failure 0))
             ; (fun () ->
                 failure_order := 1 :: !failure_order;
                 raise (Branch_failure 1))
             ; (fun () -> emit gate ())
             ; (fun () ->
                 sibling_prefix := true;
                 pause ();
                 sibling_suffix := true)
             ]
         with Branch_failure index ->
           selected := index;
           caught_at := !now)
   with Branch_failure _ -> escaped_execute := true);
  if !escaped_execute then
    failwith "parallel exception escaped its lexical handler";
  if List.rev !failure_order <> [ 1; 0 ] then
    failwith "test did not raise branch failures in temporal reverse order";
  if !selected <> 0 then
    failwith "parallel did not select the lowest failing branch index";
  if !caught_at <> 0 then
    failwith "parallel exception crossed an instant boundary";
  if (not !sibling_prefix) || !sibling_suffix then
    failwith "parallel did not apply weak sibling preemption";
  (!selected, !caught_at, !sibling_prefix, !sibling_suffix)

let delayed_descendant_failure () =
  let now = ref (-1) in
  let failed_at = ref (-1) in
  let caught_at = ref (-1) in
  let child_one_ticks = ref [] in
  let child_two_ticks = ref [] in
  let failing_finally = ref false in
  let rec service ticks () =
    ticks := !now :: !ticks;
    pause ();
    service ticks ()
  in
  execute ~instants:4 ~on_snapshot:(record_instant now) (fun _input _output ->
      try
        parallel
          [
            (fun () ->
              Fun.protect
                ~finally:(fun () -> failing_finally := true)
                (fun () ->
                  pause ();
                  failed_at := !now;
                  raise Delayed_failure))
          ; (fun () ->
              parallel [ service child_one_ticks; service child_two_ticks ])
          ]
      with Delayed_failure -> caught_at := !now);
  if !failed_at <> 1 || !caught_at <> 1 then
    failwith
      "delayed parallel exception was not re-raised in its failing instant";
  if List.rev !child_one_ticks <> [ 0; 1 ] then
    failwith "first descendant crossed the failure boundary";
  if List.rev !child_two_ticks <> [ 0; 1 ] then
    failwith "second descendant crossed the failure boundary";
  if not !failing_finally then
    failwith "failing branch did not unwind its own OCaml stack";
  (!failed_at, !caught_at, List.length !child_one_ticks, !failing_finally)

let awaited_failure_cleanup () =
  let now = ref (-1) in
  let failed_at = ref (-1) in
  let caught_at = ref (-1) in
  let blocked_suffix = ref false in
  let final_awaiters = ref (-1) in
  let final_kill_watchers = ref (-1) in
  let final_live_tasks = ref (-1) in
  let on_snapshot (snapshot : runtime_snapshot) =
    record_instant now snapshot;
    match snapshot.phase with
    | `After_finalize ->
        final_awaiters := snapshot.awaiters;
        final_kill_watchers := snapshot.kill_watchers;
        final_live_tasks := snapshot.live_tasks
    | `Before_step | `After_step | `After_rollover -> ()
  in
  execute ~instants:4 ~on_snapshot (fun _input _output ->
      let trigger = new_signal () in
      let never = new_signal () in
      let stop = new_signal () in
      try
        parallel
          [
            (fun () ->
              ignore (await trigger);
              failed_at := !now;
              raise Awaited_failure)
          ; (fun () -> emit trigger ())
          ; (fun () ->
              watch stop (fun () ->
                  ignore (await never);
                  blocked_suffix := true))
          ]
      with Awaited_failure -> caught_at := !now);
  if !failed_at <> 1 || !caught_at <> 1 then
    failwith "awaited branch failure did not propagate in its resuming instant";
  if !blocked_suffix then
    failwith "blocked sibling survived an awaited branch failure";
  if !final_awaiters <> 0 || !final_kill_watchers <> 0 then
    failwith "parallel failure left signal registrations behind";
  if !final_live_tasks <> 0 then
    failwith "parallel failure left scheduler tasks behind";
  ( !failed_at
  , !caught_at
  , !blocked_suffix
  , !final_awaiters
  , !final_kill_watchers
  , !final_live_tasks )

let () =
  let empty_at, singleton_at = trivial_completion () in
  let selected, selected_at, sibling_prefix, sibling_suffix =
    same_instant_selection ()
  in
  let failed_at, caught_at, descendant_ticks, failing_finally =
    delayed_descendant_failure ()
  in
  let ( awaited_at
      , awaited_caught_at
      , blocked_suffix
      , awaiters
      , kill_watchers
      , live_tasks ) =
    awaited_failure_cleanup ()
  in
  Format.printf "empty=%d singleton=%d@.%!" empty_at singleton_at;
  Format.printf "selected=%d caught=%d sibling_prefix=%b sibling_suffix=%b@.%!"
    selected selected_at sibling_prefix sibling_suffix;
  Format.printf
    "delayed=%d caught=%d descendant_ticks=%d failing_finally=%b@.%!" failed_at
    caught_at descendant_ticks failing_finally;
  Format.printf
    "awaited=%d caught=%d blocked_suffix=%b awaiters=%d kill_watchers=%d \
     live_tasks=%d@.%!"
    awaited_at awaited_caught_at blocked_suffix awaiters kill_watchers
    live_tasks
