type property = string

type location = string
module AbstractLocation = String
let loc_prefix : location = "o_"

module LocationSet = Set.Make(AbstractLocation)
