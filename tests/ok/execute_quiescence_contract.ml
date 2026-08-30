open Tempo

let failf format = Format.kasprintf failwith format

let () =
  let polls = ref 0 in
  let main_started = ref false in
  let received = ref None in
  execute ~instants:3
    ~input:(fun () ->
      incr polls;
      if !polls = 2 then Some 42 else None)
    (fun input _output ->
      main_started := true;
      received := Some (await input));
  if not !main_started then failwith "main did not run in the first instant";
  if !polls <> 1 then
    failf "quiescent execution polled input %d times instead of once" !polls;
  if !received <> None then
    failwith "a future input restarted a quiescent execution"

let () =
  let polls = ref 0 in
  let outputs = ref 0 in
  let snapshots = ref 0 in
  let main_started = ref false in
  execute ~instants:0
    ~input:(fun () ->
      incr polls;
      Some ())
    ~output:(fun () -> incr outputs)
    ~on_snapshot:(fun _ -> incr snapshots)
    (fun _input _output -> main_started := true);
  if !polls <> 0 then
    failf "zero-instant execution polled input %d times" !polls;
  if !outputs <> 0 then
    failf "zero-instant execution emitted %d outputs" !outputs;
  if !snapshots <> 0 then
    failf "zero-instant execution emitted %d snapshots" !snapshots;
  if !main_started then failwith "zero-instant execution ran main"

let () =
  let polls = ref 0 in
  let received = ref None in
  let ran_beyond_bound = ref false in
  execute ~instants:3
    ~input:(fun () ->
      incr polls;
      if !polls = 2 then Some 42 else None)
    (fun input _output ->
      parallel
        [
          (fun () -> received := Some (await input))
        ; (fun () ->
            pause ();
            pause ();
            pause ();
            ran_beyond_bound := true)
        ]);
  if !polls <> 3 then
    failf "live execution opened %d instants instead of three" !polls;
  if !received <> Some 42 then
    failwith "an explicit driver did not keep input polling alive";
  if !ran_beyond_bound then
    failwith "the instant bound did not abandon work scheduled beyond it"
