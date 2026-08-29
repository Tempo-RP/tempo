open Ppxlib
module Builder = Ast_builder.Default

let fail format = Printf.ksprintf failwith format

let location line start_column end_column =
  let position column =
    {
      Lexing.pos_fname = "parallel_source.ml"
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

let marker_of attributes =
  List.find_opt
    (fun attribute ->
      String.equal attribute.attr_name.txt
        Tempo_ppx_expander.branch_attribute_name)
    attributes

let expect_branch expected closure =
  if closure.pexp_loc <> expected.pexp_loc then
    fail "generated closure did not preserve its branch location";
  let marker =
    match marker_of closure.pexp_attributes with
    | Some marker -> marker
    | None -> fail "generated closure has no parallel branch marker"
  in
  if marker.attr_loc <> expected.pexp_loc then
    fail "parallel branch marker has the wrong location";
  (match marker.attr_payload with
  | PStr [] -> ()
  | _ -> fail "parallel branch marker unexpectedly has a payload");
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
        fail "PPX copied or replaced the original branch expression"
  | _ -> fail "parallel branch was not expanded to a unit thunk"

let () =
  let extension_loc = location 1 0 80 in
  let first = Builder.eint ~loc:(location 2 3 4) 1 in
  let second = Builder.eint ~loc:(location 3 3 4) 2 in
  let expanded =
    Tempo_ppx_expander.expand_parallel ~loc:extension_loc [ first; second ]
  in
  if expanded.pexp_loc <> extension_loc then
    fail "expanded parallel call has the wrong location";
  let branch_list =
    match expanded.pexp_desc with
    | Pexp_apply
        ( {
            pexp_desc = Pexp_ident { txt = Ldot (Lident "Tempo", "parallel"); _ }
          ; _
          }
        , [ (Nolabel, branches) ] ) ->
        branches
    | _ -> fail "extension did not expand to Tempo.parallel"
  in
  let closures = Tempo_ppx_expander.branches_of_literal branch_list in
  (match closures with
  | [ first_closure; second_closure ] ->
      expect_branch first first_closure;
      expect_branch second second_closure
  | _ -> fail "expanded parallel call has the wrong number of branches");
  let invalid = Builder.evar ~loc:(location 5 0 8) "branches" in
  let invalid_rejected =
    match Tempo_ppx_expander.branches_of_literal invalid with
    | _ -> false
    | exception Location.Error _ -> true
  in
  if not invalid_rejected then fail "dynamic branch list was accepted"
