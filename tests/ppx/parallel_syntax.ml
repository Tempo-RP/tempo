open Tempo

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let () =
  let now = ref (-1) in
  let empty_at = ref (-1) in
  let singleton_at = ref (-1) in
  let producer_started = ref false in
  let consumer_started = ref false in
  let worker_started = ref false in
  let observed = ref (-1) in
  let consumer_at = ref (-1) in
  let worker_at = ref (-1) in
  let joined_at = ref (-1) in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      let signal = new_signal () in
      [%tempo.parallel []];
      empty_at := !now;
      [%tempo.parallel [ singleton_at := !now ]];
      let ordinary_worker () =
        worker_started := true;
        pause ();
        worker_at := !now
      in
      [%tempo.parallel
        [
          (producer_started := true;
           emit signal 42)
        ; (consumer_started := true;
           let value = await signal in
           observed := value;
           consumer_at := !now)
        ; ordinary_worker ()
        ]];
      joined_at := !now);
  if !empty_at <> 0 || !singleton_at <> 0 then
    failwith "trivial PPX parallel crossed an instant boundary";
  if (not !producer_started) || (not !consumer_started) || not !worker_started
  then failwith "a PPX parallel branch did not start";
  if !observed <> 42 then failwith "await did not return the emitted value";
  if !consumer_at <> 1 || !worker_at <> 1 || !joined_at <> 1 then
    failwith "PPX parallel changed Tempo scheduling semantics"
