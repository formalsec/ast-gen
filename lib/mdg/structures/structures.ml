type property = string

type location = string
module AbstractLocation = String

let loc_obj_prefix : location = "l_"
let loc_par_prefix : location = "p_"
let loc_fun_prefix : location = "f_"

module LocationSet = struct 
  module LocationSet' = Set.Make(AbstractLocation)
  include LocationSet'

  let map_flat (f : 'a -> LocationSet'.t) (locations : LocationSet'.t) : LocationSet'.t = 
    LocationSet'.fold (fun l acc -> LocationSet'.union acc (f l)) locations LocationSet'.empty
end
