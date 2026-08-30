open Ppxlib
module Builder = Ast_builder.Default

let branch_attribute_name = "tempo.parallel_branch"
let when_body_attribute_name = "tempo.when_body"
let watch_body_attribute_name = "tempo.watch_body"

let computation_attribute ~name ~loc =
  Builder.attribute ~loc ~name:{ txt = name; loc } ~payload:(PStr [])

let wrap_computation ~attribute_name body =
  let loc = body.pexp_loc in
  let closure = Builder.pexp_fun ~loc Nolabel None (Builder.punit ~loc) body in
  {
    closure with
    pexp_attributes =
      computation_attribute ~name:attribute_name ~loc :: closure.pexp_attributes
  }

let wrap_branch = wrap_computation ~attribute_name:branch_attribute_name

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

let expand_parallel_payload ~ctxt payload =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  expand_parallel ~loc (branches_of_literal payload)

let parallel_extension =
  Extension.V3.declare "@tempo.parallel" Extension.Context.expression
    Ast_pattern.(single_expr_payload __)
    expand_parallel_payload

let raise_scope_syntax_error ~loc ~extension_name =
  Location.raise_errorf ~loc
    "%s expects exactly one signal expression and one body; use [%%%s signal \
     (body)]"
    extension_name extension_name

(* The extension brackets delimit the complete payload, not its two operands.
   Requiring one outer application argument preserves an unambiguous boundary:
   compound signal and body expressions must be grouped by ordinary OCaml
   syntax before this function sees the tree. *)
let scope_arguments ~extension_name payload =
  (match payload.pexp_attributes with
  | [] -> ()
  | attribute :: _ ->
      Location.raise_errorf ~loc:attribute.attr_loc
        "%s does not accept attributes on its application-shaped payload; \
         attach them to the signal or body expression"
        extension_name);
  match payload.pexp_desc with
  | Pexp_apply (signal, [ (Nolabel, body) ]) -> (signal, body)
  | _ -> raise_scope_syntax_error ~loc:payload.pexp_loc ~extension_name

let expand_scope ~loc ~callee ~attribute_name signal body =
  Builder.eapply ~loc (Builder.evar ~loc callee)
    [ signal; wrap_computation ~attribute_name body ]

let expand_when ~loc signal body =
  expand_scope ~loc ~callee:"Tempo.when_"
    ~attribute_name:when_body_attribute_name signal body

let expand_watch ~loc signal body =
  expand_scope ~loc ~callee:"Tempo.watch"
    ~attribute_name:watch_body_attribute_name signal body

let declare_scope_extension ~extension_name ~expand_scope =
  let expand ~ctxt payload =
    let loc = Expansion_context.Extension.extension_point_loc ctxt in
    let signal, body = scope_arguments ~extension_name payload in
    expand_scope ~loc signal body
  in
  Extension.V3.declare ("@" ^ extension_name) Extension.Context.expression
    Ast_pattern.(single_expr_payload __)
    expand

let when_extension =
  declare_scope_extension ~extension_name:"tempo.when" ~expand_scope:expand_when

let watch_extension =
  declare_scope_extension ~extension_name:"tempo.watch"
    ~expand_scope:expand_watch
