module Graph = Mdg.Graph'

type key = string

type value = Graph.t

type t = (string, value) Hashtbl.t

let empty () : t = Hashtbl.create 10

let add : t -> key -> value -> unit = Hashtbl.replace

let get : t -> key -> value = Hashtbl.find
