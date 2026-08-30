open Tempo

let record_instant now (snapshot : runtime_snapshot) =
  match snapshot.phase with
  | `Before_step -> now := snapshot.instant
  | `After_step | `After_finalize | `After_rollover -> ()

let normal_completion () =
  let now = ref (-1) in
  let call_instant = ref (-1) in
  let body_instant = ref (-1) in
  let continuation_instant = ref (-1) in
  execute ~instants:2 ~on_snapshot:(record_instant now) (fun _input _output ->
      let never = new_signal () in
      call_instant := !now;
      watch never (fun () -> body_instant := !now);
      continuation_instant := !now);
  if !call_instant < 0 || !body_instant < 0 || !continuation_instant < 0 then
    failwith "normal watch scenario did not execute completely";
  if
    !body_instant <> !call_instant
    || !continuation_instant <> !call_instant
  then
    failwith "normal watch completion crossed an instant boundary";
  (!body_instant, !continuation_instant)

let preempted_completion () =
  let now = ref (-1) in
  let call_instant = ref (-1) in
  let body_instant = ref (-1) in
  let emission_instant = ref (-1) in
  let continuation_instant = ref (-1) in
  let resumed_body = ref false in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      let stop = new_signal () in
      let body_started = new_signal () in
      let emitter () =
        ignore (await_immediate body_started);
        emission_instant := !now;
        emit stop ()
      in
      let watched () =
        call_instant := !now;
        watch stop (fun () ->
            body_instant := !now;
            emit body_started ();
            pause ();
            resumed_body := true);
        continuation_instant := !now
      in
      parallel [ emitter; watched ]);
  if
    !call_instant < 0
    || !body_instant < 0
    || !emission_instant < 0
    || !continuation_instant < 0
  then failwith "preempted watch scenario did not execute completely";
  if !resumed_body then failwith "preempted body resumed in the next instant";
  if
    !body_instant <> !call_instant
    || !emission_instant <> !body_instant
    || !continuation_instant <> !body_instant + 1
  then
    failwith "preempted watch did not resume its caller in the next instant";
  (!body_instant, !continuation_instant)

let already_present_completion () =
  let now = ref (-1) in
  let call_instant = ref (-1) in
  let body_instant = ref (-1) in
  let continuation_instant = ref (-1) in
  let resumed_body = ref false in
  execute ~instants:3 ~on_snapshot:(record_instant now) (fun _input _output ->
      let stop = new_signal () in
      emit stop ();
      call_instant := !now;
      watch stop (fun () ->
          body_instant := !now;
          pause ();
          resumed_body := true);
      continuation_instant := !now);
  if !call_instant < 0 || !body_instant < 0 || !continuation_instant < 0 then
    failwith "already-present watch scenario did not execute completely";
  if !resumed_body then failwith "already-present watch body resumed";
  if
    !body_instant <> !call_instant
    || !continuation_instant <> !body_instant + 1
  then
    failwith "already-present watch did not resume its caller next instant";
  (!body_instant, !continuation_instant)

let guarded_completion () =
  let now = ref (-1) in
  let preemption_instant = ref (-1) in
  let continuation_instant = ref (-1) in
  let resumed_body = ref false in
  execute ~instants:5 ~on_snapshot:(record_instant now) (fun _input _output ->
      let guard = new_signal () in
      let stop = new_signal () in
      let body_started = new_signal () in
      let driver () =
        emit guard ();
        ignore (await_immediate body_started);
        pause ();
        preemption_instant := !now;
        emit stop ();
        pause ();
        pause ();
        emit guard ()
      in
      let watched () =
        when_ guard (fun () ->
            watch stop (fun () ->
                emit body_started ();
                pause ();
                resumed_body := true);
            continuation_instant := !now)
      in
      parallel [ driver; watched ]);
  if !preemption_instant < 0 || !continuation_instant < 0 then
    failwith "guarded watch scenario did not execute completely";
  if !resumed_body then failwith "guarded watch body survived preemption";
  if !continuation_instant <> !preemption_instant + 2 then
    failwith "watch caller ignored its enclosing guard";
  (!preemption_instant, !continuation_instant)

let () =
  let normal_body, normal_continuation = normal_completion () in
  let preempted_body, preempted_continuation = preempted_completion () in
  let present_body, present_continuation = already_present_completion () in
  let guarded_preemption, guarded_continuation = guarded_completion () in
  Format.printf "normal=body:%d,continuation:%d@.%!" normal_body
    normal_continuation;
  Format.printf "preempted=body:%d,continuation:%d@.%!" preempted_body
    preempted_continuation;
  Format.printf "present=body:%d,continuation:%d@.%!" present_body
    present_continuation;
  Format.printf "guarded=preemption:%d,continuation:%d@.%!"
    guarded_preemption guarded_continuation
