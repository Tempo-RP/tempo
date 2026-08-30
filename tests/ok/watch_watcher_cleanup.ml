open Tempo

exception Watch_body_failure

let snapshots_checked = ref 0
let normal_completions = ref 0
let exceptional_completions = ref 0
let final_registered = ref 0
let final_pruned = ref 0
let final_fired = ref 0

let check_snapshot snapshot =
  match snapshot.phase with
  | `After_finalize ->
      incr snapshots_checked;
      final_registered := snapshot.cum_kill_watchers_registered;
      final_pruned := snapshot.cum_kill_watchers_pruned;
      final_fired := snapshot.cum_kill_watchers_fired;
      if snapshot.kill_watchers <> 0 then
        failwith "a completed watch retained its kill watcher"
  | `Before_step | `After_step | `After_rollover -> ()

let () =
  execute ~instants:6 ~on_snapshot:check_snapshot (fun _ _ ->
      let stop = new_signal () in
      let rec rounds remaining =
        if remaining > 0 then begin
          for _ = 1 to 100 do
            watch stop (fun () -> ());
            incr normal_completions
          done;
          for _ = 1 to 100 do
            match watch stop (fun () -> raise Watch_body_failure) with
            | () -> failwith "watch swallowed its body exception"
            | exception Watch_body_failure -> incr exceptional_completions
          done;
          pause ();
          rounds (remaining - 1)
        end
      in
      rounds 5);
  if !normal_completions <> 500 then
    failwith "the normal watch bodies did not all complete";
  if !exceptional_completions <> 500 then
    failwith "the exceptional watch bodies did not all complete";
  if !snapshots_checked <> 6 then
    failwith "the watcher cleanup test did not observe every finalization";
  if !final_registered <> 1_000 then
    failwith "the watcher cleanup test did not register every watcher";
  if !final_pruned <> 1_000 then
    failwith "the watcher cleanup test did not prune every completed watcher";
  if !final_fired <> 0 then
    failwith "the watcher cleanup test unexpectedly fired a watcher"

let nested_finalizations = ref 0
let nested_registered = ref 0
let nested_pruned = ref 0
let nested_fired = ref 0

let check_nested_snapshot snapshot =
  match snapshot.phase with
  | `After_finalize ->
      incr nested_finalizations;
      nested_registered := snapshot.cum_kill_watchers_registered;
      nested_pruned := snapshot.cum_kill_watchers_pruned;
      nested_fired := snapshot.cum_kill_watchers_fired;
      if snapshot.cum_kill_watchers_fired > 0 && snapshot.kill_watchers <> 0
      then failwith "signal order retained a watcher killed during finalization"
  | `Before_step | `After_step | `After_rollover -> ()

let () =
  execute ~instants:3 ~on_snapshot:check_nested_snapshot (fun _ _ ->
      let outer = new_signal () in
      let inner = new_signal () in
      parallel
        [
          (fun () ->
            watch outer (fun () ->
                watch inner (fun () ->
                    pause ();
                    pause ())))
        ; (fun () ->
            pause ();
            emit outer ())
        ]);
  if !nested_finalizations < 2 then
    failwith "the nested watcher test did not reach preemption";
  if !nested_registered <> 2 then
    failwith "the nested watcher test did not register both watchers";
  if !nested_fired <> 1 then
    failwith "the outer watcher did not fire exactly once";
  if !nested_pruned <> 1 then
    failwith "the inner watcher was not pruned after outer preemption"
