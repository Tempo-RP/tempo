type ('emit, 'agg, 'mode) signal_core =
  ('emit, 'agg, 'mode) Tempo_core.signal_core

let rec pause_n n =
  if n <= 0 then ()
  else (
    Tempo_core.pause ();
    pause_n (n - 1))

let after_n n body =
  if n < 0 then invalid_arg "after_n expects n >= 0";
  pause_n n;
  body ()

let every_n n body =
  if n <= 0 then invalid_arg "every_n expects n > 0";
  let rec loop_every () =
    pause_n n;
    body ();
    loop_every ()
  in
  loop_every ()

let timeout n ~on_timeout body =
  if n < 0 then invalid_arg "timeout expects n >= 0";
  let timeout_signal = Tempo_core.new_signal () in
  Tempo_core.parallel
    [
      (fun () ->
        after_n n (fun () ->
            Tempo_core.emit timeout_signal ();
            on_timeout ()));
      (fun () -> Tempo_core.watch timeout_signal body);
    ]

let cooldown n s body =
  if n < 0 then invalid_arg "cooldown expects n >= 0";
  let rec loop_cooldown armed =
    if armed then (
      pause_n n;
      loop_cooldown false)
    else (
      let _ = Tempo_core.await s in
      body ();
      loop_cooldown true)
  in
  loop_cooldown false

let supervise_until stop body = Tempo_core.watch stop body

let rec loop p () =
  p ();
  Tempo_core.pause ();
  loop p ()

let rec idle () =
  Tempo_core.pause ();
  idle ()
