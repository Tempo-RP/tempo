open Tempo

let watch_continued = ref false
let parallel_completed = ref false

let scenario () =
  let stop = new_signal () in
  let guard = new_signal () in
  let watched () =
    watch stop (fun () ->
        when_ guard (fun () -> failwith "guarded body must not run"));
    watch_continued := true
  in
  let driver () = emit stop () in
  parallel [ watched; driver ];
  parallel_completed := true

let () =
  execute (fun _ _ -> scenario ());
  if not !watch_continued then
    failwith "watch continuation did not resume after preemption";
  if not !parallel_completed then
    failwith "killed guard-blocked task kept the parallel join active";
  Format.printf "watch_continued=%b@.%!" !watch_continued;
  Format.printf "parallel_completed=%b@.%!" !parallel_completed
