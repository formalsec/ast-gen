
type property = string

type location = string
module AbstractLocation = String

let loc_obj_prefix  : location = "l_" 
let loc_par_prefix  : location = "p_"
let loc_fun_prefix  : location = "f_"
let loc_sink_prefix : location = "s_"

let loc_literal : location = loc_obj_prefix ^ "literal"
let loc_taint_source : location = loc_obj_prefix ^ "tsource"
let loc_this : location = "this"

module LocationSet = struct 
  module LocationSet' = Set.Make(AbstractLocation)
  include LocationSet'

  let map_flat (f : 'a -> LocationSet'.t) (locations : LocationSet'.t) : LocationSet'.t = 
    LocationSet'.fold (fun l acc -> LocationSet'.union acc (f l)) locations LocationSet'.empty

  let apply (f : 'a -> unit) (locations : LocationSet'.t) = 
    LocationSet'.iter f locations

  let print (locations : LocationSet'.t) : unit = 
    apply (fun loc -> print_string (loc ^ ", ") ) locations;
    print_newline ();
end

module AliasSet = Set.Make(String)
