open Tempo

exception Body_failure
exception Elided_body_failure
exception Present_body_failure

let caught_inside = ref 0
let continued_after_catch = ref 0
let resumed_after_signal = ref false
let caught_elided = ref 0
let caught_present = ref 0
let escaped_execute = ref false

let regular_watch_exception () =
  (try
     execute ~instants:4 (fun _input _output ->
         let stop = new_signal () in
         (try
            watch stop (fun () ->
                pause ();
                raise Body_failure)
          with Body_failure -> incr caught_inside);
         incr continued_after_catch;
         emit stop ();
         pause ();
         resumed_after_signal := true)
   with Body_failure -> escaped_execute := true);
  if !caught_inside <> 1 then failwith "body exception bypassed the watch caller";
  if !continued_after_catch <> 1 then
    failwith "watch caller continuation ran more than once";
  if not !resumed_after_signal then
    failwith "watch caller did not remain live after the watched signal";
  if !escaped_execute then failwith "body exception escaped execute"

let elided_watch_exception () =
  execute ~instants:4 (fun _input _output ->
      let stop = new_signal () in
      watch stop (fun () ->
          (try
             watch stop (fun () ->
                 pause ();
                 raise Elided_body_failure)
           with Elided_body_failure -> incr caught_elided);
          pause ()))

let already_present_watch_exception () =
  execute ~instants:2 (fun _input _output ->
      let stop = new_signal () in
      emit stop ();
      try watch stop (fun () -> raise Present_body_failure)
      with Present_body_failure -> incr caught_present)

let () =
  regular_watch_exception ();
  elided_watch_exception ();
  already_present_watch_exception ();
  if !caught_elided <> 1 then
    failwith "elided watch exception bypassed the watch caller";
  if !caught_present <> 1 then
    failwith "exception did not win over already-present preemption";
  Format.printf
    "caught_inside=%d continued_after_catch=%d resumed_after_signal=%b \
     caught_elided=%d caught_present=%d escaped_execute=%b@.%!"
    !caught_inside !continued_after_catch !resumed_after_signal !caught_elided
    !caught_present !escaped_execute
