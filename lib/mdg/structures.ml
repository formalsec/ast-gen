type property = string

type location = string
module AbstractLocation = String
let loc_prefix : location = "o_"


module HashTable = Hashtbl.Make(struct
    type t = string
    let equal = String.equal
    let hash = Hashtbl.hash
end)

module LocationSet = Set.Make(AbstractLocation)
