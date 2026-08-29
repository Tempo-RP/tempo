open Tempo

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let () =
  let now = ref (-1) in
  let guard_evaluations = ref 0 in
  let ordinary_worker_ran = ref false in
  let normal_watch_body_at = ref (-1) in
  let normal_watch_continued_at = ref (-1) in
  let when_result = ref None in
  let when_body_started = ref false in
  let when_finished_at = ref (-1) in
  let watched_started = ref 0 in
  let watched_suffixes = ref 0 in
  let watch_continued_at = ref (-1) in
  let joined_at = ref (-1) in
  execute ~instants:4 ~on_snapshot:(record_instant now) (fun _input _output ->
      let immediate_guard = new_signal () in
      let never = new_signal () in
      emit immediate_guard ();
      let guard_expression () =
        incr guard_evaluations;
        immediate_guard
      in
      let atomic_result = [%tempo.when (guard_expression ()) 41] in
      let ordinary_worker () =
        ordinary_worker_ran := true;
        42
      in
      let ordinary_result =
        [%tempo.when immediate_guard (ordinary_worker ())]
      in
      [%tempo.watch
        never
          begin
            normal_watch_body_at := !now
          end];
      normal_watch_continued_at := !now;
      if atomic_result <> 41 || ordinary_result <> 42 then
        failwith "tempo.when did not preserve its body result";
      let guard = new_signal () in
      let payload = new_signal () in
      let stop = new_signal () in
      let first_ready = new_signal () in
      let second_ready = new_signal () in
      [%tempo.parallel
        [
          (let value =
             [%tempo.when
               guard
                 (when_body_started := true;
                  await payload)]
           in
           when_result := Some value;
           when_finished_at := !now)
        ; (pause ();
           if !when_body_started then
             failwith "tempo.when body started before its guard was present";
           emit guard ();
           emit payload 42;
           pause ();
           emit guard ())
        ; ([%tempo.watch
             stop
               [%tempo.parallel
                 [
                   (incr watched_started;
                    emit first_ready ();
                    pause ();
                    incr watched_suffixes)
                 ; (incr watched_started;
                    emit second_ready ();
                    pause ();
                    incr watched_suffixes)
                 ]]];
           watch_continued_at := !now)
        ; (let () = await_immediate first_ready in
           let () = await_immediate second_ready in
           emit stop ())
        ]];
      joined_at := !now);
  if !guard_evaluations <> 1 then
    failwith "tempo.when evaluated its signal expression more than once";
  if not !ordinary_worker_ran then
    failwith "ordinary function body was not explicitly applied";
  if !normal_watch_body_at <> 0 || !normal_watch_continued_at <> 0 then
    failwith "normally completed tempo.watch crossed an instant boundary";
  if !when_result <> Some 42 || !when_finished_at <> 2 then
    failwith
      (Printf.sprintf
         "suspended tempo.when changed reactive timing or result: result=%s, \
          instant=%d"
         (match !when_result with
         | None -> "none"
         | Some value -> string_of_int value)
         !when_finished_at);
  if !watched_started <> 2 then
    failwith "tempo.watch did not start both nested parallel branches";
  if !watched_suffixes <> 0 then
    failwith "nested parallel branches survived tempo.watch preemption";
  if !watch_continued_at <> 1 then
    failwith "preempted tempo.watch resumed its caller at the wrong instant";
  if !joined_at <> 2 then
    failwith "scope syntax changed nested parallel join timing"
