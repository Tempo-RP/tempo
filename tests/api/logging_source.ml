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
    message (fun ?header ?tags:_ format ->
        Format.kasprintf
          (fun text ->
            messages := (source, level, header, text) :: !messages;
            over ();
            continue ())
          format)
  in
  { Logs.report }

let () =
  let messages = ref [] in
  Logs.set_reporter (recording_reporter messages);
  Logs.set_level None;
  Logs.Src.set_level Tempo.Logging.source (Some Logs.Info);
  if Logs.level () <> None then
    failwith "enabling Tempo changed the application's global log level";
  if not (String.equal (Logs.Src.name Tempo.Logging.source) "tempo.runtime")
  then failwith "Tempo exposes an unexpectedly named logging source";
  Tempo.execute ~instants:0 (fun _input _output -> ());
  let emitted = List.length !messages in
  (match !messages with
  | [] -> failwith "the enabled Tempo source emitted no runtime diagnostic"
  | messages ->
      List.iter
        (fun (source, level, header, text) ->
          if not (Logs.Src.equal source Tempo.Logging.source) then
            failwith "a Tempo diagnostic used another Logs source";
          if level <> Logs.Info then
            failf "expected an info diagnostic, got %s"
              (Logs.level_to_string (Some level));
          if
            String.equal text
              "==================== runtime start | schedule initial task=#%d \
               ===================="
          then
            failf "an unexpanded formatter escaped into a diagnostic: %S" text;
          match header with
          | Some "execute" -> ()
          | Some actual -> failf "unexpected Tempo log scope %S" actual
          | None -> failwith "a Tempo diagnostic lost its structured scope")
        messages);
  Logs.Src.set_level Tempo.Logging.source (Some Logs.App);
  Tempo.execute ~instants:0 (fun _input _output -> ());
  if List.length !messages <> emitted then
    failwith "an App-only Tempo source emitted an Info runtime diagnostic";
  Logs.Src.set_level Tempo.Logging.source None;
  Tempo.execute ~instants:0 (fun _input _output -> ());
  if List.length !messages <> emitted then
    failwith "the disabled Tempo source still emitted a runtime diagnostic";
  messages := [];
  let host_source =
    Logs.Src.create ~doc:"Host logging policy sentinel" "tempo.test.host"
  in
  Logs.Src.set_level host_source (Some Logs.Info);
  let host_marker text =
    Logs.msg ~src:host_source Logs.Info (fun log -> log "%s" text)
  in
  host_marker "before execute";
  Tempo.execute ~instants:1 (fun _input _output -> host_marker "inside execute");
  host_marker "after execute";
  if Logs.level () <> None then
    failwith "execute changed the application's global log level";
  if Logs.Src.level host_source <> Some Logs.Info then
    failwith "execute changed an application source level";
  match List.rev !messages with
  | [
    (before_source, Logs.Info, None, "before execute")
  ; (inside_source, Logs.Info, None, "inside execute")
  ; (after_source, Logs.Info, None, "after execute")
  ]
    when Logs.Src.equal before_source host_source
         && Logs.Src.equal inside_source host_source
         && Logs.Src.equal after_source host_source ->
      ()
  | _ -> failwith "execute disrupted the application reporter"
