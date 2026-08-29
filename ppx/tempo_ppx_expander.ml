open Ppxlib
module Builder = Ast_builder.Default

let branch_attribute_name = "tempo.parallel_branch"

let branch_attribute ~loc =
  Builder.attribute ~loc
    ~name:{ txt = branch_attribute_name; loc }
    ~payload:(PStr [])

let wrap_branch body =
  let loc = body.pexp_loc in
  let closure = Builder.pexp_fun ~loc Nolabel None (Builder.punit ~loc) body in
  {
    closure with
    pexp_attributes = branch_attribute ~loc :: closure.pexp_attributes
  }

let reject_list_attributes expression =
  match expression.pexp_attributes with
  | [] -> ()
  | attribute :: _ ->
      Location.raise_errorf ~loc:attribute.attr_loc
        "tempo.parallel does not accept attributes on the literal list \
         structure; attach them to individual branch expressions"

let rec branches_of_literal expression =
  reject_list_attributes expression;
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Lident "[]"; _ }, None) -> []
  | Pexp_construct
      ( { txt = Lident "::"; _ }
      , Some ({ pexp_desc = Pexp_tuple [ head; tail ]; _ } as pair) ) ->
      reject_list_attributes pair;
      head :: branches_of_literal tail
  | _ ->
      Location.raise_errorf ~loc:expression.pexp_loc
        "tempo.parallel expects a literal OCaml list of branch expressions"

let expand_parallel ~loc branches =
  Builder.eapply ~loc
    (Builder.evar ~loc "Tempo.parallel")
    [ Builder.elist ~loc (List.map wrap_branch branches) ]

let expand ~ctxt payload =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  expand_parallel ~loc (branches_of_literal payload)

let parallel_extension =
  Extension.V3.declare "@tempo.parallel" Extension.Context.expression
    Ast_pattern.(single_expr_payload __)
    expand
