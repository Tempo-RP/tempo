val branch_attribute_name : string
val branches_of_literal : Ppxlib.expression -> Ppxlib.expression list

val expand_parallel :
  loc:Ppxlib.Location.t -> Ppxlib.expression list -> Ppxlib.expression

val parallel_extension : Ppxlib.Extension.t
