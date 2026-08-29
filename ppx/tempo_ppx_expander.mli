val branch_attribute_name : string
val when_body_attribute_name : string
val watch_body_attribute_name : string
val branches_of_literal : Ppxlib.expression -> Ppxlib.expression list

val expand_parallel :
  loc:Ppxlib.Location.t -> Ppxlib.expression list -> Ppxlib.expression

val expand_when :
     loc:Ppxlib.Location.t
  -> Ppxlib.expression
  -> Ppxlib.expression
  -> Ppxlib.expression

val expand_watch :
     loc:Ppxlib.Location.t
  -> Ppxlib.expression
  -> Ppxlib.expression
  -> Ppxlib.expression

val parallel_extension : Ppxlib.Extension.t
val when_extension : Ppxlib.Extension.t
val watch_extension : Ppxlib.Extension.t
