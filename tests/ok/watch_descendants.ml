open Tempo

let child_one_started = ref false
let child_one_resumed = ref false
let child_two_started = ref false
let child_two_resumed = ref false
let watch_continued = ref false

let () =
  execute ~instants:3 (fun _input _output ->
      let stop = new_signal () in
      let child_one_ready = new_signal () in
      let child_two_ready = new_signal () in
      let emitter () =
        ignore (await_immediate child_one_ready);
        ignore (await_immediate child_two_ready);
        emit stop ()
      in
      let child ready started resumed () =
        started := true;
        emit ready ();
        pause ();
        resumed := true
      in
      let watched () =
        watch stop (fun () ->
            parallel
              [ child child_one_ready child_one_started child_one_resumed
              ; child child_two_ready child_two_started child_two_resumed
              ]);
        watch_continued := true
      in
      parallel [ emitter; watched ]);
  if not !child_one_started || not !child_two_started then
    failwith "watch descendants did not start in the current instant";
  if !child_one_resumed || !child_two_resumed then
    failwith "watch descendants survived preemption";
  if not !watch_continued then failwith "watch caller did not resume";
  Format.printf "children_started=%b children_resumed=%b continued=%b@.%!"
    (!child_one_started && !child_two_started)
    (!child_one_resumed || !child_two_resumed)
    !watch_continued
