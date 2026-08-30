let failf fmt = Format.kasprintf failwith fmt

let recording_reporter messages =
  let report : type a b.
         Logs.src
      -> Logs.level
      -> over:(unit -> unit)
      -> (unit -> b)
      -> (a, b) Logs.msgf
      -> b =
   fun source level ~over continue message ->
    message (fun ?header:_ ?tags:_ format ->
        Format.kasprintf
          (fun text ->
            messages := (source, level, text) :: !messages;
            over ();
            continue ())
          format)
  in
  { Logs.report }

let expect_level label expected actual =
  if actual <> expected then
    failf "%s: expected level %s, got %s" label
      (Logs.level_to_string expected)
      (Logs.level_to_string actual)

let () =
  if Array.length Sys.argv < 2 then invalid_arg "missing Tempo plugin path";
  ignore Mtime.Span.zero;
  ignore (Mtime_clock.now ());
  let plugin = Sys.argv.(1) in
  let messages = ref [] in
  let application_reporter = recording_reporter messages in
  Logs.set_reporter application_reporter;
  Logs.set_level (Some Logs.Debug);
  let sentinel =
    Logs.Src.create ~doc:"Tempo logging isolation sentinel"
      "tempo.test.sentinel"
  in
  Logs.Src.set_level sentinel (Some Logs.Error);
  Logs.debug (fun log -> log "before loading Tempo");
  let messages_before_load = List.length !messages in
  (match Dynlink.loadfile plugin with
  | () -> ()
  | exception Dynlink.Error error ->
      failf "could not load Tempo: %s" (Dynlink.error_message error));
  expect_level "global logging policy" (Some Logs.Debug) (Logs.level ());
  expect_level "existing source policy" (Some Logs.Error)
    (Logs.Src.level sentinel);
  let tempo_sources =
    List.filter
      (fun source -> String.equal (Logs.Src.name source) "tempo.runtime")
      (Logs.Src.list ())
  in
  (match tempo_sources with
  | [ source ] ->
      expect_level "Tempo source inherited policy" (Some Logs.Debug)
        (Logs.Src.level source)
  | sources ->
      failf "expected one tempo.runtime source, found %d" (List.length sources));
  Logs.Src.set_level Logs.default (Some Logs.Debug);
  Logs.debug (fun log -> log "after loading Tempo");
  if List.length !messages <> messages_before_load + 1 then
    failwith "loading Tempo disconnected the application reporter"
