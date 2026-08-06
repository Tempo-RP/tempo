open Tempo

let ran_current = ref false
let ran_next = ref false
let after_watch = ref false

let scenario () =
  let stop = new_signal () in
  emit stop ();
  watch stop (fun () ->
      ran_current := true;
      pause ();
      ran_next := true);
  after_watch := true

let () =
  execute (fun _ _ -> scenario ());
  if not !ran_current then failwith "watch body did not run in current instant";
  if !ran_next then failwith "watch body resumed after preemption";
  if not !after_watch then failwith "parent continuation did not resume"
