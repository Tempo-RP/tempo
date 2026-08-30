open Tempo

exception Body_failure

let caught_inside = ref false
let escaped_execute = ref false

let () =
  (try
     execute ~instants:3 (fun _input _output ->
         let guard = new_signal () in
         let driver () =
           emit guard ();
           pause ();
           emit guard ()
         in
         let worker () =
           try
             ignore
               (when_ guard (fun () ->
                    pause ();
                    raise Body_failure))
           with Body_failure -> caught_inside := true
         in
         parallel [ driver; worker ])
   with Body_failure -> escaped_execute := true);
  if not !caught_inside then failwith "body exception bypassed the when_ caller";
  if !escaped_execute then failwith "body exception escaped execute";
  Format.printf "caught_inside=%b escaped_execute=%b@.%!" !caught_inside
    !escaped_execute
