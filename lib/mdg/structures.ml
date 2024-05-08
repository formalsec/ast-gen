open Auxiliary.Functions

type property = string

type location = string
module AbstractLocation = String
let loc_prefix : location = "o_"


module HashTable = Hashtbl.Make(struct
    type t = string
    let equal = String.equal
    let hash = Hashtbl.hash
end)

(* ------- S T O R E ------- *)
module LocationSet = Set.Make(AbstractLocation)


(* ------- G R A P H ------- *)


module Edge = struct
    type info = 
        | Property of property option
        | Version  of property option
        | Dependency
        | Argument of string   
        | Parameter of string 
        | Call 

    type t = {
        _to  : location;
        info : info;
      } 

    let compare ({_to; info} : t) ({_to=_to'; info=info'} : t) : int = 
        Bool.to_int (_to = _to' && info = info') - 1

    let to_string ({_to; info} : t) : string = 
        let edge_info = match info with 
            | Property prop -> map_default (fun prop -> "P(" ^ prop ^ ")") "P(*)" prop
            | Version prop -> map_default (fun prop -> "V(" ^ prop ^ ")") "V(*)" prop
            | Dependency -> "D" 
            | Argument id -> "ARG(" ^ id ^ ")"
            | Parameter pos -> "param " ^ pos
            | Call -> "CG"
        in 
        " --" ^ edge_info ^ "-> " ^ _to 

    let get_property (info : info) : property = 
        match info with 
            | Property prop
            | Version prop -> map_default (identity) ("*") prop
            | _ -> failwith "provided edge has no property"

end

module EdgeSet = Set.Make(Edge)
