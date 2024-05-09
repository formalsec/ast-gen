type property = string

type location = string
module AbstractLocation = String

let loc_obj_prefix : location = "l_"
let loc_par_prefix : location = "p_"
let loc_fun_prefix : location = "f_"

module LocationSet = Set.Make(AbstractLocation)
