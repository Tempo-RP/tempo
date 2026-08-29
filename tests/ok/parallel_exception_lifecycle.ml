open Tempo

type lifecycle = Request_quit

exception Quit_request

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let now = ref (-1)
let failure_at = ref (-1)
let caught_at = ref (-1)
let execute_returned = ref false
let transport_ticks = ref []
let audio_ticks = ref []
let render_ticks = ref []
let host_outputs = ref []

let service ticks () =
  let rec loop () =
    ticks := !now :: !ticks;
    pause ();
    loop ()
  in
  loop ()

let output_service output () =
  let rec loop () =
    emit output !now;
    pause ();
    loop ()
  in
  loop ()

let () =
  (try
     execute ~instants:6 ~on_snapshot:(record_instant now)
       ~output:(fun instant -> host_outputs := instant :: !host_outputs)
       (fun _input output ->
         let lifecycle = new_signal () in
         let transport () =
           emit lifecycle Request_quit;
           service transport_ticks ()
         in
         let lifecycle_process () =
           match await lifecycle with
           | Request_quit ->
               pause ();
               failure_at := !now;
               raise Quit_request
         in
         parallel
           [
             transport
           ; lifecycle_process
           ; service audio_ticks
           ; service render_ticks
           ; output_service output
           ]);
     execute_returned := true
   with Quit_request -> caught_at := !now);
  if !execute_returned then
    failwith "lifecycle branch failure did not leave execute";
  if !failure_at <> 2 || !caught_at <> 2 then
    failwith "lifecycle failure was not propagated in its current instant";
  if List.rev !transport_ticks <> [ 0; 1; 2 ] then
    failwith "transport survived lifecycle failure";
  if List.rev !audio_ticks <> [ 0; 1; 2 ] then
    failwith "audio service survived lifecycle failure";
  if List.rev !render_ticks <> [ 0; 1; 2 ] then
    failwith "render service survived lifecycle failure";
  if List.rev !host_outputs <> [ 0; 1 ] then
    failwith "execute flushed host output after its top-level exception";
  Format.printf
    "failure=%d caught=%d execute_returned=%b service_ticks=%d \
     host_outputs=%d@.%!"
    !failure_at !caught_at !execute_returned
    (List.length !transport_ticks)
    (List.length !host_outputs)
