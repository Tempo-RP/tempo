open Ppxlib
module Builder = Ast_builder.Default

let fail format = Printf.ksprintf failwith format

let location line start_column end_column =
  let position column =
    {
      Lexing.pos_fname = "scope_source.ml"
    ; pos_lnum = line
    ; pos_bol = 0
    ; pos_cnum = column
    }
  in
  {
    Location.loc_start = position start_column
  ; loc_end = position end_column
  ; loc_ghost = false
  }

let marker_of name attributes =
  List.find_opt
    (fun attribute -> String.equal attribute.attr_name.txt name)
    attributes

let expect_computation ~marker_name expected closure =
  if closure.pexp_loc <> expected.pexp_loc then
    fail "generated computation did not preserve its body location";
  let marker =
    match marker_of marker_name closure.pexp_attributes with
    | Some marker -> marker
    | None -> fail "generated computation has no %s marker" marker_name
  in
  if marker.attr_loc <> expected.pexp_loc then
    fail "%s marker has the wrong location" marker_name;
  (match marker.attr_payload with
  | PStr [] -> ()
  | _ -> fail "%s marker unexpectedly has a payload" marker_name);
  match closure.pexp_desc with
  | Pexp_function
      ( [
          {
            pparam_desc =
              Pparam_val
                ( Nolabel
                , None
                , {
                    ppat_desc = Ppat_construct ({ txt = Lident "()"; _ }, None)
                  ; _
                  } )
          ; _
          }
        ]
      , None
      , Pfunction_body body ) ->
      if not (body == expected) then
        fail "PPX copied or replaced the original scope body"
  | _ -> fail "scope body was not expanded to a unit thunk"

let expect_scope ~callee ~marker_name ~extension_loc ~signal ~body expanded =
  if expanded.pexp_loc <> extension_loc then
    fail "expanded %s call has the wrong location" callee;
  match expanded.pexp_desc with
  | Pexp_apply
      ( { pexp_desc = Pexp_ident { txt = Ldot (Lident "Tempo", actual); _ }; _ }
      , [ (Nolabel, actual_signal); (Nolabel, computation) ] )
    when String.equal actual callee ->
      if not (actual_signal == signal) then
        fail "%s copied or replaced the signal expression" callee;
      expect_computation ~marker_name body computation
  | _ -> fail "extension did not expand to Tempo.%s" callee

let () =
  let extension_loc = location 1 0 80 in
  let signal = Builder.evar ~loc:(location 2 3 9) "signal" in
  let when_body = Builder.eint ~loc:(location 3 3 5) 42 in
  let watch_body =
    Builder.pexp_construct ~loc:(location 4 3 5)
      { txt = Lident "()"; loc = location 4 3 5 }
      None
  in
  expect_scope ~callee:"when_"
    ~marker_name:Tempo_ppx_expander.when_body_attribute_name ~extension_loc
    ~signal ~body:when_body
    (Tempo_ppx_expander.expand_when ~loc:extension_loc signal when_body);
  expect_scope ~callee:"watch"
    ~marker_name:Tempo_ppx_expander.watch_body_attribute_name ~extension_loc
    ~signal ~body:watch_body
    (Tempo_ppx_expander.expand_watch ~loc:extension_loc signal watch_body)
