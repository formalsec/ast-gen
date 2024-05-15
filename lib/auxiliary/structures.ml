module HashTable = struct 
    module Table = Hashtbl.Make(struct
        type t = string
        let equal = String.equal
        let hash = Hashtbl.hash
    end)

    include Table
    let equals (eq : 'a -> 'a -> bool) (table : 'a Table.t) (table' : 'a Table.t) : bool = 
        if Table.length table == Table.length table'
            then Table.fold (fun key value acc -> acc && (Table.mem table' key) && (eq value (Table.find table' key))) table true
            else false
end
    