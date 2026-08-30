open Tempo

exception Program_failure
exception Input_failure
exception Output_failure
exception Snapshot_failure
exception Combine_failure

let failf fmt = Format.kasprintf failwith fmt
let completed_execution = "Tempo: signal belongs to a completed execution"

let assert_expired label signal value =
  match emit signal value with
  | () -> failf "%s: an expired signal accepted an emission" label
  | exception Invalid_argument message
    when String.equal message completed_execution ->
      ()
  | exception Invalid_argument message ->
      failf "%s: unexpected expiration error %S" label message

let assert_collected label weak =
  Gc.full_major ();
  Gc.full_major ();
  match Weak.get weak 0 with
  | None -> ()
  | Some _ -> failf "%s: a suspended continuation was retained" label

let normal_signal : int signal option ref = ref None
let normal_token = Weak.create 1
let normal_finally_ran = ref false
let normal_awaiter_seen = ref false

let run_normal_teardown () =
  execute
    ~on_snapshot:(fun snapshot ->
      if snapshot.phase = `After_finalize && snapshot.awaiters = 1 then
        normal_awaiter_seen := true)
    (fun _ _ ->
      let signal = new_signal () in
      normal_signal := Some signal;
      let token = ref 0 in
      Weak.set normal_token 0 (Some token);
      Fun.protect
        ~finally:(fun () -> normal_finally_ran := true)
        (fun () ->
          ignore (await signal);
          incr token))

let () =
  run_normal_teardown ();
  if not !normal_awaiter_seen then
    failwith "the normal teardown probe never registered its awaiter";
  if !normal_finally_ran then
    failwith "runtime teardown unwound a suspended continuation";
  assert_expired "normal teardown" (Option.get !normal_signal) 0;
  assert_collected "normal teardown" normal_token

let guarded_signal : unit signal option ref = ref None
let guarded_token = Weak.create 1
let guarded_body_started = ref false
let guarded_continuation_ran = ref false

let run_guarded_teardown () =
  execute ~instants:1 (fun _ _ ->
      let signal = new_signal () in
      guarded_signal := Some signal;
      let token = ref 0 in
      Weak.set guarded_token 0 (Some token);
      when_ signal (fun () -> guarded_body_started := true);
      guarded_continuation_ran := true;
      incr token)

let () =
  run_guarded_teardown ();
  if !guarded_body_started then
    failwith "an absent guard unexpectedly started its body";
  if !guarded_continuation_ran then
    failwith "an absent guard unexpectedly resumed its continuation";
  assert_expired "guarded teardown" (Option.get !guarded_signal) ();
  assert_collected "guarded teardown" guarded_token

let bounded_signal : int signal option ref = ref None
let bounded_token = Weak.create 1
let bounded_branch_started = ref false

let run_bounded_teardown () =
  execute ~instants:1 (fun _ _ ->
      let signal = new_signal () in
      bounded_signal := Some signal;
      parallel
        [
          (fun () ->
            bounded_branch_started := true;
            let token = ref 0 in
            Weak.set bounded_token 0 (Some token);
            ignore (await signal);
            incr token)
        ; (fun () ->
            pause ();
            pause ())
        ])

let () =
  run_bounded_teardown ();
  if not !bounded_branch_started then
    failwith "the bounded teardown branch never started";
  assert_expired "bounded teardown" (Option.get !bounded_signal) 0;
  assert_collected "bounded teardown" bounded_token

let exceptional_signal : int signal option ref = ref None
let exceptional_token = Weak.create 1
let exceptional_finally_ran = ref false
let exceptional_branch_started = ref false

let run_exceptional_teardown () =
  try
    execute (fun _ _ ->
        let signal = new_signal () in
        exceptional_signal := Some signal;
        parallel
          [
            (fun () ->
              exceptional_branch_started := true;
              let token = ref 0 in
              Weak.set exceptional_token 0 (Some token);
              Fun.protect
                ~finally:(fun () -> exceptional_finally_ran := true)
                (fun () ->
                  ignore (await signal);
                  incr token))
          ; (fun () ->
              pause ();
              raise Program_failure)
          ]);
    failwith "the program exception was swallowed"
  with Program_failure -> ()

let () =
  run_exceptional_teardown ();
  if not !exceptional_branch_started then
    failwith "the exceptional teardown branch never started";
  if !exceptional_finally_ran then
    failwith "exceptional teardown unwound a suspended sibling";
  assert_expired "exceptional teardown" (Option.get !exceptional_signal) 0;
  assert_collected "exceptional teardown" exceptional_token

let input_signal : int signal option ref = ref None
let input_token = Weak.create 1
let input_polls = ref 0
let input_branch_started = ref false

let run_input_failure_teardown () =
  try
    execute
      ~input:(fun () ->
        incr input_polls;
        if !input_polls = 2 then raise Input_failure else None)
      (fun _ _ ->
        let signal = new_signal () in
        input_signal := Some signal;
        parallel
          [
            (fun () ->
              input_branch_started := true;
              let token = ref 0 in
              Weak.set input_token 0 (Some token);
              ignore (await signal);
              incr token)
          ; (fun () -> pause ())
          ]);
    failwith "the input exception was swallowed"
  with Input_failure -> ()

let () =
  run_input_failure_teardown ();
  if !input_polls <> 2 then failwith "the input callback was not called twice";
  if not !input_branch_started then
    failwith "the input failure teardown branch never started";
  assert_expired "input callback teardown" (Option.get !input_signal) 0;
  assert_collected "input callback teardown" input_token

let output_signal : int signal option ref = ref None
let output_token = Weak.create 1
let output_branch_started = ref false

let run_output_failure_teardown () =
  try
    execute
      ~output:(fun () -> raise Output_failure)
      (fun _ output ->
        output_branch_started := true;
        let signal = new_signal () in
        output_signal := Some signal;
        emit output ();
        let token = ref 0 in
        Weak.set output_token 0 (Some token);
        ignore (await signal);
        incr token);
    failwith "the output exception was swallowed"
  with Output_failure -> ()

let () =
  run_output_failure_teardown ();
  if not !output_branch_started then
    failwith "the output failure teardown branch never started";
  assert_expired "output callback teardown" (Option.get !output_signal) 0;
  assert_collected "output callback teardown" output_token

let snapshot_signal : int signal option ref = ref None
let snapshot_token = Weak.create 1
let snapshot_branch_started = ref false

let run_snapshot_failure_teardown () =
  try
    execute
      ~on_snapshot:(fun snapshot ->
        if snapshot.phase = `After_step then raise Snapshot_failure)
      (fun _ _ ->
        snapshot_branch_started := true;
        let signal = new_signal () in
        snapshot_signal := Some signal;
        let token = ref 0 in
        Weak.set snapshot_token 0 (Some token);
        ignore (await signal);
        incr token);
    failwith "the snapshot exception was swallowed"
  with Snapshot_failure -> ()

let () =
  run_snapshot_failure_teardown ();
  if not !snapshot_branch_started then
    failwith "the snapshot failure teardown branch never started";
  assert_expired "snapshot callback teardown" (Option.get !snapshot_signal) 0;
  assert_collected "snapshot callback teardown" snapshot_token

let combine_signal : (int, int) agg_signal option ref = ref None

let run_combine_failure_teardown () =
  try
    execute (fun _ _ ->
        let signal =
          new_signal_agg ~initial:0 ~combine:(fun _ _ -> raise Combine_failure)
        in
        combine_signal := Some signal;
        emit signal 1);
    failwith "the aggregate combine exception was swallowed"
  with Combine_failure -> ()

let () =
  run_combine_failure_teardown ();
  assert_expired "aggregate combine teardown" (Option.get !combine_signal) 0

let watched_signal : unit signal option ref = ref None
let awaited_signal : int signal option ref = ref None
let watch_body_token = Weak.create 1
let watch_continuation_token = Weak.create 1
let watch_body_started = ref false
let watch_continuation_ran = ref false
let watch_finally_ran = ref false

let run_watch_teardown () =
  execute (fun _ _ ->
      let watched = new_signal () in
      let awaited = new_signal () in
      watched_signal := Some watched;
      awaited_signal := Some awaited;
      let continuation_token = ref 0 in
      Weak.set watch_continuation_token 0 (Some continuation_token);
      watch watched (fun () ->
          watch_body_started := true;
          let body_token = ref 0 in
          Weak.set watch_body_token 0 (Some body_token);
          Fun.protect
            ~finally:(fun () -> watch_finally_ran := true)
            (fun () ->
              ignore (await awaited);
              incr body_token));
      watch_continuation_ran := true;
      incr continuation_token)

let () =
  run_watch_teardown ();
  if not !watch_body_started then failwith "the watch body never started";
  if !watch_continuation_ran then
    failwith "the suspended watch continuation unexpectedly resumed";
  if !watch_finally_ran then
    failwith "runtime teardown unwound a suspended watch body";
  assert_expired "watched signal teardown" (Option.get !watched_signal) ();
  assert_expired "awaited signal teardown" (Option.get !awaited_signal) 0;
  assert_collected "watch body teardown" watch_body_token;
  assert_collected "watch continuation teardown" watch_continuation_token
