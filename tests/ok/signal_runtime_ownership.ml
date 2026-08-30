open Tempo

let completed_execution = "Tempo: signal belongs to a completed execution"
let another_execution = "Tempo: signal belongs to another execution"
let failf fmt = Format.kasprintf failwith fmt

let expect_invalid_argument label expected action =
  match action () with
  | () -> failf "%s: expected Invalid_argument" label
  | exception Invalid_argument actual when String.equal actual expected -> ()
  | exception Invalid_argument actual ->
      failf "%s: expected %S, got %S" label expected actual

let expired_event : int signal option ref = ref None
let expired_awaiter_resumed = ref false

let () =
  execute (fun _ _ ->
      let signal = new_signal () in
      expired_event := Some signal;
      ignore (await signal);
      expired_awaiter_resumed := true)

let () =
  if !expired_awaiter_resumed then
    failwith "an awaiter resumed after its execution completed"

let () =
  let signal = Option.get !expired_event in
  expect_invalid_argument "expired emit outside execute" completed_execution
    (fun () -> emit signal 1)

let () =
  let signal = Option.get !expired_event in
  let when_body_started = ref false in
  let watch_body_started = ref false in
  let after_finalize = ref None in
  execute
    ~on_snapshot:(fun snapshot ->
      if snapshot.phase = `After_finalize then after_finalize := Some snapshot)
    (fun _ _ ->
      expect_invalid_argument "expired emit" completed_execution (fun () ->
          emit signal 1);
      expect_invalid_argument "expired await" completed_execution (fun () ->
          ignore (await signal));
      expect_invalid_argument "expired await_immediate" completed_execution
        (fun () -> ignore (await_immediate signal));
      expect_invalid_argument "expired when" completed_execution (fun () ->
          when_ signal (fun () -> when_body_started := true));
      expect_invalid_argument "expired watch" completed_execution (fun () ->
          watch signal (fun () -> watch_body_started := true));
      let local = new_signal () in
      emit local 42;
      if await_immediate local <> 42 then
        failwith "the current execution was poisoned by an ownership error");
  if !when_body_started then failwith "expired when body started";
  if !watch_body_started then failwith "expired watch body started";
  match !after_finalize with
  | None -> failwith "missing After_finalize snapshot"
  | Some snapshot ->
      if snapshot.tracked_signals <> 0 then
        failwith "an expired signal was tracked by the current execution";
      if snapshot.cum_signals_tracked <> 1 then
        failf "expected one local tracked signal, got %d"
          snapshot.cum_signals_tracked

let expired_aggregate : (int, int) agg_signal option ref = ref None
let combine_calls = ref 0

let () =
  execute (fun _ _ ->
      expired_aggregate :=
        Some
          (new_signal_agg ~initial:0 ~combine:(fun acc value ->
               incr combine_calls;
               acc + value)))

let () =
  let signal = Option.get !expired_aggregate in
  execute (fun _ _ ->
      expect_invalid_argument "expired aggregate emit" completed_execution
        (fun () -> emit signal 1);
      expect_invalid_argument "expired aggregate await" completed_execution
        (fun () -> ignore (await signal));
      expect_invalid_argument "expired aggregate when" completed_execution
        (fun () -> when_ signal (fun () -> ())));
  if !combine_calls <> 0 then
    failwith "an expired aggregate invoked its combine callback"

let inner_signal : int signal option ref = ref None

let () =
  let foreign_when_started = ref false in
  let foreign_watch_started = ref false in
  let foreign_combine_calls = ref 0 in
  execute (fun _ _ ->
      let outer_signal = new_signal () in
      let outer_aggregate =
        new_signal_agg ~initial:0 ~combine:(fun acc value ->
            incr foreign_combine_calls;
            acc + value)
      in
      execute (fun _ _ ->
          let local = new_signal () in
          inner_signal := Some local;
          expect_invalid_argument "foreign emit" another_execution (fun () ->
              emit outer_signal 1);
          expect_invalid_argument "foreign await" another_execution (fun () ->
              ignore (await outer_signal));
          expect_invalid_argument "foreign await_immediate" another_execution
            (fun () -> ignore (await_immediate outer_signal));
          expect_invalid_argument "foreign when" another_execution (fun () ->
              when_ outer_signal (fun () -> foreign_when_started := true));
          expect_invalid_argument "foreign watch" another_execution (fun () ->
              watch outer_signal (fun () -> foreign_watch_started := true));
          expect_invalid_argument "foreign aggregate emit" another_execution
            (fun () -> emit outer_aggregate 1);
          emit local 7;
          if await_immediate local <> 7 then
            failwith "the nested execution was poisoned by an ownership error";
          when_ local (fun () ->
              expect_invalid_argument "foreign when with colliding signal id"
                another_execution (fun () ->
                  when_ outer_signal (fun () -> foreign_when_started := true)));
          watch local (fun () ->
              expect_invalid_argument "foreign watch with colliding signal id"
                another_execution (fun () ->
                  watch outer_signal (fun () -> foreign_watch_started := true))));
      if !foreign_when_started then failwith "foreign when body started";
      if !foreign_watch_started then failwith "foreign watch body started";
      if !foreign_combine_calls <> 0 then
        failwith "a foreign aggregate invoked its combine callback";
      let expired_inner = Option.get !inner_signal in
      expect_invalid_argument "expired inner signal" completed_execution
        (fun () -> emit expired_inner 1);
      emit outer_signal 9;
      if await_immediate outer_signal <> 9 then
        failwith "the outer signal became invalid after nested execute";
      emit outer_aggregate 2;
      if !foreign_combine_calls <> 1 then
        failwith "the outer aggregate became invalid after nested execute")

let expired_input : int signal option ref = ref None
let expired_output : int signal option ref = ref None

let () =
  execute
    ~input:(fun () -> (None : int option))
    ~output:(fun (_ : int) -> ())
    (fun input output ->
      expired_input := Some input;
      expired_output := Some output);
  expect_invalid_argument "expired host input" completed_execution (fun () ->
      ignore (await (Option.get !expired_input)));
  expect_invalid_argument "expired host output" completed_execution (fun () ->
      emit (Option.get !expired_output) 1)
